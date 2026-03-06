{
  hostname ? null,
  port ? 8967,
  settings,
}:
{
  config,
  ...
}:
let
  hostName = if hostname == null then config.networking.hostName else hostname;
in
{
  services = {
    frigate = {
      enable = true;
      hostname = hostName;
      inherit settings;
    };

    nginx.virtualHosts.${hostName} = {
      listen = [
        {
          addr = "[::]";
          inherit port;
        }
      ];
    };
  };

}
