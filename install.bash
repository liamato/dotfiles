#! /bin/bash

#pushd . > /dev/null

## Broken links in .
# find . -maxdepth 1 -mindepth 1 -type l -exec sh -c "file -b {} | grep -q ^broken" \; -print | cut -d/ -f2

# TEMP="$(mktemp -d 2>/dev/null || mktemp -d -t 'OMZtmpdir')"
readonly REPO="https://github.com/liamato/dotfiles.git"
readonly OMZ_REPO="https://github.com/robbyrussell/oh-my-zsh.git"

declare -a ARGS
declare ARG
declare INSTALL_DIR="$HOME/.dotfiles"
declare OMZ=1
declare ATOM=1
declare FONTS=1
declare THEMES=1
declare REPLACE=0

_error() {
    (>&2 echo $@)
}

_beginswith() {
    [ "${1#$2}" != "${1}" ]
    return $?
}

_lower(){
    echo $1 | tr '[:upper:]' '[:lower:]'
}

_clean_broken_links() {
    local src=$(find . -maxdepth 1 -mindepth 1 -type l -exec sh -c "file -b {} | grep -q ^broken" \; -print | cut -d/ -f2)
    local link
    local response
    for link in $src; do
        echo -W "Wana remove $link -> $(readlink -f $link) (y/n)? "
        read response
        if _beginswith "$(_lower $response)" "y"; then
            unlink $link
            echo "removed: $link"
        fi
    done
}

_create_backup_file_name() {
    local x=1
    if [ -f $1.backup ]; then
        while [ -e $1.backup.$x ]; do
            x=$[$x+1];
        done
        while [ $x -gt 1 ]; do
            mv $1.backup.$[$x-1] $1.backup.$x
            x=$[$x-1]
            error "$x"
        done
        mv $1.backup $1.backup.$x
    fi
    echo $1.backup
}

_link_folder_contents_recursive(){
    local src="$(readlink -f $(find $1 -maxdepth 1 -mindepth 1 ) | sort -u)"
    local dest="$(readlink -f $2)"
    local response

    #echo src: $src
    #echo dest: $dest
    local x
    for x in $src; do
        if [ -d $x ]; then
            #echo "dir: $dest/$(basename $x)"
            mkdir -p $dest/$(basename $x)
            _link_folder_contents_recursive $x "$dest/$(basename $x)"
        else
            if [ -e $dest/$(basename $x) -a $REPLACE -eq 0 ]; then
                echo -E "Wana backup and replace $dest/$(basename $x) (y/n)? "
                read response

                if ! _beginswith "$(_lower $response)" "y"; then
                    continue
                fi

                mv $dest/$(basename $x) "$(_create_backup_file_name $dest/$(basename $x))"
                echo "Backup'd: $dest/$(basename $x) => $(_create_backup_file_name $dest/$(basename $x))"
            fi
            # echo "Linked: $dest/$(basename $x) -> $x"
            ln -s $x $dest -f
        fi
    done
}

_copy_folder_contents_recursive(){
    local src
    IFS=':' read -d='' -r -a src <<< "$(echo $(find $1 -maxdepth 1 -mindepth 1 | sort -u | sed 's/ /\\ /g') | sed 's/\s/:/g' | sed 's/\\:/ /g')"
    local dest="$(readlink -f $2)"
    local response

    # echo -e "src: ${src[@]}\n"
    # echo -e "dest: $dest\n"
    local x
    for x in "${src[@]}"; do
        x="$(readlink -f "$x")"
        # echo -e "dir: $dest/$(basename "$x")\t\t \$x: \"$x\"\n"
        if [ -d "$x" -a ! -e "$dest/$(basename "$x")" ]; then
            mkdir -p "$dest/$(basename "$x")"
        else
            if [ -e "$dest/$(basename "$x")" -a $REPLACE -eq 0 ]; then
                echo -E "Wana backup and replace $dest/$(basename "$x") (y/n)? "
                read response

                if ! _beginswith "$(_lower $response)" "y"; then
                    continue
                fi

                mv "$dest/$(basename "$x")" "$(_create_backup_file_name "$dest/$(basename "$x")")"
                echo "Backup'd: $dest/$(basename "$x") => $(_create_backup_file_name "$dest/$(basename "$x")")"
            fi
        fi
        # echo "Copied: $dest/$(basename "$x") -> $x"
        cp "$x" "$dest" -fr
    done
}

_help_message() {
    echo -e "Usage:\n\033[1m$0 [options]\033[0m\n    \033[1m-h, --help\033[0m\n\t\tThis help message\n    \033[1m-d=\033[0m\033[4mDIR\033[0m\033[1m, --install-dir=\033[0m\033[4mDIR\033[0m\n\t\tInstalls the dotfiles to \033[0m\033[4mDIR\033[0m\n    \033[1m-r, --replace\033[0m\n\t\tDoesn't ask before replacing files\033[0m\n    \033[1m--no-omz\033[0m\n\t\tDoesn't install oh-my-zsh\033[0m\n    \033[1m--no-atom\033[0m\n\t\tDoesn't install the atom customitzation\033[0m\n    \033[1m--no-fonts\033[0m\n\t\tDoesn't install the fonts\033[0m\n    \033[1m--no-themes\033[0m\n\t\tDoesn't install the themes\033[0m"
}

for ARG in "$@"
do
    case $ARG in
        -h|--help)
            _help_message
            exit 0
            ;;

        -d=*|--install-dir=*)
            INSTALL_DIR="${ARG#*=}"
            #shift # past argument=value
            ;;
        --no-omz)
            OMZ=0
            ;;
        --no-atom)
            ATOM=0
            ;;
        --no-fonts)
            FONTS=0
            ;;
        -r|--replace)
            REPLACE=1
            ;;
        --no-themes)
            THEMES=0
            ;;
        *)
            ARGS[${#ARGS[@]}]="$i"
            ;;
    esac
done

unset ARG

# Checks the availability of git
type -fP git 2>&1 > /dev/null
if [ $? -ne 0 ]; then
    error -e "\033[1;31;1mError:\033[0m\033[31m Git isn't on the \033[3m\$PATH\033[0m"
    exit 1
fi

echo -e "\nInstalling .dotfiles ..."
git clone --progress $REPO $INSTALL_DIR

# Installs OMZ as submodule of .dotfiles
if [ $OMZ -eq 1 ];  then
    echo -e "\nInstalling OMZ\n"
    pushd $INSTALL_DIR > /dev/null
    git submodule add -f --name "OMZ" $OMZ_REPO OMZ
    pushd $INSTALL_DIR/OMZ > /dev/null
    git checkout master
    git pull
    popd > /dev/null
    popd > /dev/null
fi

echo -e "\nLinking config files"
_link_folder_contents_recursive $INSTALL_DIR/dotfiles/ $HOME

echo -e "\nSeting defaults"
_copy_folder_contents_recursive $INSTALL_DIR/defaults/ $HOME

# Installs gnome iconpacks
if [ $THEMES -eq 1 -a "$(ls /usr/bin/*session* | grep -F gnome -q; echo $?)" -eq "0" ]; then
    echo -e "\nInstalling gnome themes"
    bash -c "$INSTALL_DIR/third-party/flat-remix.install $INSTALL_DIR"
    bash -c "$INSTALL_DIR/third-party/xenlism-wildfire.install $INSTALL_DIR"
fi

# Installs the iosevka font
if [ $FONTS -eq 1 ]; then
    echo -e "\nInstalling fonts"
    bash -c "$INSTALL_DIR/third-party/iosevka.install $INSTALL_DIR"
fi

if [ $ATOM -eq 1 ]; then
    echo -e "\nConfiguring atom"
    _copy_folder_contents_recursive $INSTALL_DIR/atom/.atom $HOME/.atom

    type -fP apm 2>&1 > /dev/null
    if [ $? -eq 0 ]; then
        # Installs the atom packages of the apm.list file
        apm install -c --packages-file $INSTALL_DIR/atom/apm.list -q
    fi
fi

# Adds template-files
type -fP xdg-user-dir 2>&1 > /dev/null
if [ $? -eq 0 ]; then
    echo -e "\nInstalling template-files"
    _copy_folder_contents_recursive $INSTALL_DIR/file-templates/ $(xdg-user-dir TEMPLATES)
fi

unset INSTALL_DIR ARGS OMZ ATOM FONTS
unset _error _beginswith _lower _clean_broken_links _create_backup_file_name _link_folder_contents_recursive _help_message

echo -e "\nDone\n"
