if command -sq ghci
    set -gx GHCUP_INSTALL_BASE_PREFIX ~/.local/share
    set -g fish_user_paths $HOME/.cabal/bin $GHCUP_INSTALL_BASE_PREFIX/.ghcup/bin $fish_user_paths
end
