{ config, ... }:
let
  vs = config.vault-secrets.secrets;
in
{
  power.ups = {
    enable = true;
    mode = "netserver";

    users = {
      "admin" = {
        passwordFile = "${vs.nut-users}/admin";
        upsmon = "primary";
        instcmds = [ "ALL" ];
        actions = [ "SET" ];
      };
      "nutmon" = {
        passwordFile = "${vs.nut-users}/nutmon";
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
    passwordPath = "${vs.nut-users}/nutmon";
  };

  vault-secrets.secrets.nut-users = {
    services = [
      "upsd"
      "upsmon"
      "prometheus-nut-exporter"
    ];
  };

  systemd.services.nut-users-secrets = {
    startLimitIntervalSec = 0;
    startLimitBurst = 0;
  };
}
