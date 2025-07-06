{
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
  sops.secrets."tsnsrv/auth_key" = { };
  sops.secrets."keys/ssh/id_ed25519_sk" = { };
  sops.secrets."home/penthouse/latitude" = { };
  sops.secrets."home/penthouse/longitude" = { };
  sops.secrets."home/penthouse/elevation" = { };
}
