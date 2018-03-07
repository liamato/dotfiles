# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.
if [ -z "$BASH_VERSION" ]; then
pushd() {
    CD="$(pwd)"
    cd $1
    echo $1
}

popd() {
    cd $CD
    echo $CD
    unset CD
}
fi

pushd . > /dev/null
cd $(dirname $(readlink -f $HOME/.profile))
if [ -z "$BASH_VERSION" ]; then
    . ../shells/sh/env
else
    . ../shells/bash/env
fi
popd > /dev/null

# if running bash
if [ -z "$BASH_VERSION" ]; then
    ssfile "login"
    export ENV="$(sfile interactive)"
else
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        ssource "$HOME/.bashrc"
    fi
fi
