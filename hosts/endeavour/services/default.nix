{ config, pkgs, ... }:

{
  imports = [
    ./arr.nix
    ./auth
    ./cloud.nix
    ./hass.nix
    ./monitoring.nix
  ];

  services = {
    openssh.enable = true;
    openssh.settings.PermitRootLogin = "no";
    openssh.settings.PasswordAuthentication = false;

    # Yubikey stuff
    udev.packages = with pkgs; [ yubikey-personalization ];
    pcscd.enable = true;

    # Enable resolved and avahi
    resolved.enable = true;
    avahi.enable = true;
    # Enable tailscale
    tailscale.enable = true;

    cloudflare-warp.enable = true;
    cloudflare-warp.openFirewall = false;

    tsnsrv = {
      enable = true;
      defaults.authKeyPath = config.sops.secrets."tsnsrv/auth_key".path;
      defaults.urlParts.host = "localhost";
    };

    postgresql = {
      enable = true;
      authentication = pkgs.lib.mkOverride 10 ''
        #type database  DBuser  auth-method
        local all       all     trust
      '';
    };
  };

}
