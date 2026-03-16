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

    systemd.services.frigate.path = [pkgs.go2rtc];

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
}
