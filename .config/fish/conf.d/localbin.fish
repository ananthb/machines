if test -d ~/.local/bin
  contains ~/.local/bin $fish_user_paths; or set -Ua fish_user_paths ~/.local/bin
  # fish 3.2.0: fish_add_path ~/.local/bin
end
