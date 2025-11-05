{ config, ... }:

{
  power.ups = {
    enable = true;
    mode = "netserver";

    users = {
      "admin" = {
        passwordFile = config.sops.secrets."nut/users/admin".path;
        upsmon = "primary";
        instcmds = [ "ALL" ];
        actions = [ "SET" ];
      };
      "nutmon" = {
        passwordFile = config.sops.secrets."nut/users/nutmon".path;
        upsmon = "primary";
      };
    };

    upsd.listen = [
      { address = "::0"; }
      { address = "0.0.0.0"; }
    ];

    ups."apc1" = {
      driver = "usbhid-ups";
      port = "auto";
      description = "APC BackUPS Pro 1000 in Imagine";
    };

    upsmon.monitor."apc1" = {
      powerValue = 1;
      user = "nutmon";
    };
  };

  services.prometheus.exporters.nut = {
    enable = true;
    nutUser = "nutmon";
    passwordPath = config.sops.secrets."nut/users/nutmon".path;
  };

  sops.secrets."nut/users/admin" = { };
}
