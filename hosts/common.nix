{
  pkgs,
  nixpkgs-unstable,
  username,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (final: prev: {
      unstable = import nixpkgs-unstable {
        inherit (final) system config;
      };
    })
  ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  environment.systemPackages = with pkgs; [
    git-credential-manager
  ];

  users.users.${username}.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINu7u4V6khhhUvepvptel86DN3XMCwZVdQe/7P6WW1KmAAAAFXNzaDphbmFudGhzLXNzaC1rZXktMQ== ananth@yubikey-5c"
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIFCVZPWg3DVxjuORNKJnjaRSPoZ4nYnzM070q0fIeM32AAAAG3NzaDphbmFudGhzLXNzaC1rZXktNWMtbmFubw== ananth@yubikey-5c-nano
"
  ];

  sops.defaultSopsFile = ../secrets.yaml;
  sops.secrets = {
    "keys/ssh/yubikey_5c" = { };
    "keys/ssh/yubikey_5c.pub" = { };
    "keys/ssh/yubikey_5c_nano" = { };
    "keys/ssh/yubikey_5c_nano.pub" = { };
    "passwords/nut/nutmon" = { };
  };
}
