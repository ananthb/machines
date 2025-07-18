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
  sops.secrets."keys/ssh/id_ed25519_sk" = { };
  sops.secrets."keys/ssh/id_ed25519_sk.pub" = { };
  sops.secrets."home/6a/latitude" = {
    owner = config.users.users.hass.name;
  };
  sops.secrets."home/6a/longitude" = {
    owner = config.users.users.hass.name;
  };
  sops.secrets."home/6a/elevation" = {
    owner = config.users.users.hass.name;
  };
}
