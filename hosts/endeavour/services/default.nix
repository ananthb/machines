{ config, pkgs, hostname, ... }:

{
  imports = [
    ./arr.nix
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

    samba = {
      enable = true;
      securityType = "user";
      openFirewall = true;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "Samba Server %v";
          "netbios name" = "${hostname}";
          "security" = "user";
          "use sendfile" = "yes";
          # note: localhost is the ipv6 localhost ::1
          "hosts allow" = "10.15.16.0 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "bad user";
        };
        "media" = {
          "path" = "/var/lib/media";
          "browseable" = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = "jellyfin";
          "force group" = "media";
        };
      };
    };

    samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    tsnsrv = {
      enable = true;
      defaults.authKeyPath = config.sops.secrets."tsnsrv/auth_key".path;
      defaults.urlParts.host = "localhost";
    };
  };
}
