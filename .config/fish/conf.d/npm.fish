set NPM_PREFIX ~/.local/lib/node_modules

if test -d $NPM_PREFIX
  set -gx MANPATH $NPM_PREFIX/share/man $MANPATH
end

