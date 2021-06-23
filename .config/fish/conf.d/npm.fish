set NPM_PREFIX ~/.local/lib/node_modules

if test -d $NPM_PREFIX
    fish_add_path $NPM_PREFIX/bin
    set -gx MANPATH $NPM_PREFIX/share/man $MANPATH
end

