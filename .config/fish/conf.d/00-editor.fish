if command -q nvim
  set -gx EDITOR nvim
  set -gx VISUAL $EDITOR
end
