{
  pkgs,
  nixpkgs-unstable,
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

  sops.defaultSopsFile = ../secrets.yaml;
  sops.secrets = {
    "keys/ssh/yubikey_5c" = { };
    "keys/ssh/yubikey_5c.pub" = { };
    "keys/ssh/yubikey_5c_nano" = { };
    "keys/ssh/yubikey_5c_nano.pub" = { };
    "passwords/nut/nutmon" = { };
  };
}
