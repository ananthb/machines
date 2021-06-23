set npm_prefix ~/.local/lib/node_modules

if test -d $npm_prefix
  contains $npm_prefix $fish_user_paths; or set -Ua fish_user_paths $npm_prefix/bin
  # fish 3.2.0: fish_add_path $npm_prefix/bin
  set -gx MANPATH $npm_prefix/share/man $MANPATH
end

