set -gx RUSTUP_HOME ~/.local/share/rustup
set -gx CARGO_HOME ~/.local/share/cargo
set -g fish_user_paths $CARGO_HOME/bin $fish_user_paths
