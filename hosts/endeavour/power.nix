{ config, ... }:

{
  power.ups = {
    enable = true;
    mode = "netserver";
    openFirewall = true;

    users = {
      "admin" = {
        passwordFile = config.sops.secrets."passwords/nut/admin".path;
        instcmds = "ALL";
        actions = "SET";
      };
      "upsmon" = {
        passwordFile = config.sops.secrets."passwords/nut/upsmon".path;
        upsmon = "primary";
      };
    };

    upsd.listen = [
      { address = "::"; }
    ];

    ups."apc1" = {
      driver = "usbhid-ups";
      port = "auto";
      description = "Server UPS";
    };

    upsmon.monitor."apc1" = {
      powerValue = 1;
      user = "upsmon";
    };
  };

  sops.secrets."passwords/nut/upsmon" = { };
}
