{
  config,
  pkgs,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  environment.systemPackages = with pkgs; [
    git-credential-manager
  ];

  sops.defaultSopsFile = ../secrets.yaml;
  sops.secrets."keys/ssh/yubikey_5c" = { };
  sops.secrets."keys/ssh/yubikey_5c.pub" = { };
  sops.secrets."keys/ssh/yubikey_5c_nano" = { };
  sops.secrets."keys/ssh/yubikey_5c_nano.pub" = { };
  sops.secrets."tsnsrv/auth_key" = { };
  sops.secrets."tsnsrv/tailnet" = { };
}
