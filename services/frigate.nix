{
  hostname ? null,
  port ? 8967,
  settings,
}: {
  config,
  pkgs,
  ...
}: let
  hostName =
    if hostname == null
    then config.networking.hostName
    else hostname;
in {
  systemd.services.frigate.path = [pkgs.go2rtc];

  services = {
    frigate = {
      enable = true;
      hostname = hostName;
      inherit settings;
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
}
