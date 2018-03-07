# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

pushd . > /dev/null
cd $(dirname $(readlink -f $HOME/.bashrc))
. ../shells/bash/env
popd > /dev/null

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

ssfile "interactive"
