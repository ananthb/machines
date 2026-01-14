{ config, ... }:
{
  my-services.rclone-syncs."taxes-sync" = {
    type = "bisync";
    source = "seafile:";
    sourceSubPath = "/Finance/Taxes";
    destination = "gdrive:";
    destSubPath = "/Taxes";
    rcloneConfig = config.sops.secrets."rclone/conf".path;
    interval = "daily";
    environment = {
      RCLONE_CONFIG_SEAFILE_URL = "http://localhost:4444/seafdav";
      RCLONE_CONFIG_SEAFILE_TYPE = "webdav";
      RCLONE_CONFIG_SEAFILE_VENDOR = "other";
    };
  };

  sops.secrets."rclone/conf" = { };
}
