{
  pkgs,
  pkgs-unstable,
  ...
}:
{
  environment.systemPackages = with pkgs-unstable; [
    jellyfin-web
    jellyfin-ffmpeg
  ];

  services = {
    jellyfin.enable = true;
    jellyfin.package = pkgs-unstable.jellyfin;
    jellyfin.group = "media";
    jellyfin.openFirewall = true;

    meilisearch.enable = true;
    meilisearch.package = pkgs.meilisearch;
    meilisearch.listenAddress = "[::]";

    tsnsrv.services.tv = {
      funnel = true;
      urlParts.port = 8096;
    };

  };

  systemd.services.tsnsrv-tv.wants = [ "jellyfin.service" ];
  systemd.services.tsnsrv-tv.after = [ "jellyfin.service" ];

}
