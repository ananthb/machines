{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./arr.nix
    ./cloud.nix
    ./hass.nix
    ./homepage.nix
    ./monitoring.nix
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = false;
  };

  # Yubikey stuff
  services.udev.packages = with pkgs; [ yubikey-personalization ];
  services.pcscd.enable = true;

  # Enable resolved and avahi
  services.resolved.enable = true;
  services.avahi.enable = true;

  # Enable tailscale
  services.tailscale.enable = true;

  services.cloudflare-warp.enable = true;
  services.cloudflare-warp.openFirewall = false;

  services.tsnsrv = {
    enable = true;
    defaults.authKeyPath = config.sops.secrets."tsnsrv/auth_key".path;
    defaults.urlParts.host = "localhost";
  };
}
