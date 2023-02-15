set -gx fish_greeting ""
set -gx LESSCHARSET utf-8
# GPG needs this for some reason.
set -gx GPG_TTY (tty)
set -gx NEOVIDE_MULTIGRID true

fish_add_path ~/.local/bin

if command -q nvim
  set -gx EDITOR nvim
  set -gx VISUAL $EDITOR
end
