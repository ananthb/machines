{ config, ... }:
{
  sops.secrets."rclone/conf" = { };

  my-services.rclone-syncs."seafile-to-gdrive" = {
    # 'seafile' and 'gdrive' must be defined in the rclone.conf secret
    source = "seafile:/";
    destination = "gdrive:/Backups/Seafile";
    rcloneConfig = config.sops.secrets."rclone/conf".path;
    interval = "daily";
    environment = {
      # Override the Seafile URL to use the local network
      RCLONE_CONFIG_SEAFILE_URL = "http://enterprise.local:4000/seafdav";
      RCLONE_CONFIG_SEAFILE_TYPE = "webdav";
      RCLONE_CONFIG_SEAFILE_VENDOR = "other";
    };
  };
}
