set -gx GHCUP_INSTALL_BASE_PREFIX ~/.local/share
set -gx PATH "$HOME/.cabal/bin:$GHCUP_INSTALL_BASE_PREFIX/.ghcup/bin" $PATH
