{ ... }:
{
  services.radarr = {
    enable = true;
    group = "media";
    openFirewall = true;
  };
  systemd.services.radarr = {
    serviceConfig.UMask = "0002";
    after = [
      "postgresql.service"
      "qbittorrent.service"
    ];
    wants = [
      "postgresql.service"
      "qbittorrent.service"
    ];
  };
}
