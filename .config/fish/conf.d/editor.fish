if command -qv nvim
  set -gx EDITOR nvim
  set -gx VISUAL $EDITOR
end
