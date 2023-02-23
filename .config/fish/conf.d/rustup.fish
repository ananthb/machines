set -gx RUSTUP_HOME $HOME/.local/share/rustup
set -gx CARGO_HOME $HOME/.local/share/cargo

if test -d $CARGO_HOME
  fish_add_path $CARGO_HOME/bin
end
