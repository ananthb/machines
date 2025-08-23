{ config, ... }:

{
  power.ups = {
    enable = true;
    mode = "netserver";
    openFirewall = true;

    users = {
      "admin" = {
        passwordFile = config.sops.secrets."passwords/nut/admin".path;
        upsmon = "primary";
        instcmds = [ "ALL" ];
        actions = [ "SET" ];
      };
      "nutmon" = {
        passwordFile = config.sops.secrets."passwords/nut/nutmon".path;
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

  sops.secrets."passwords/nut/admin" = { };
  sops.secrets."passwords/nut/nutmon" = { };
}
