
pushd . > /dev/null
cd $(dirname $(readlink -f $HOME/.zshenv))
. ../shells/zsh/env
popd > /dev/null
