{ ... }:
{
  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };
  systemd.services.prowlarr = {
    after = [
      "postgresql.service"
      "radarr.service"
      "sonarr.service"
      "qbittorrent.service"
    ];
    wants = [
      "postgresql.service"
      "radarr.service"
      "sonarr.service"
      "qbittorrent.service"
    ];
  };
}
