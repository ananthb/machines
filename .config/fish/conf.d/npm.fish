set npm_prefix ~/.local/lib/node_modules

if test -d $npm_prefix
  fish_add_path $npm_prefix/bin
  set -gx MANPATH $npm_prefix/share/man $MANPATH
end

