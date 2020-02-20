set NPM_PREFIX ~/.local/lib/node_modules

if test -d $NPM_PREFIX
    set -g fish_user_paths $NPM_PREFIX/bin $fish_user_paths
    set -gx MANPATH $NPM_PREFIX/share/man $MANPATH
end

