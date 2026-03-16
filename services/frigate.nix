{
  hostname ? null,
  port ? 8967,
  settings,
}: {config, ...}: let
  hostName =
    if hostname == null
    then config.networking.hostName
    else hostname;
in {
  services = {
    frigate = {
      enable = true;
      hostname = hostName;
      inherit settings;
    };

    go2rtc = {
      enable = true;
      settings = settings.go2rtc or {};
    };

    nginx.virtualHosts.${hostName} = {
      listen = [
        {
          addr = "0.0.0.0";
          inherit port;
        }
        {
          addr = "[::]";
          inherit port;
        }
      ];
    };
  };

  systemd.services.frigate = {
    after = ["go2rtc.service"];
    wants = ["go2rtc.service"];
  };
}
