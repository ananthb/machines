{ config, ... }:
{
  # Expected secrets.yaml structure for rclone/conf:
  #
  # [webdav]
  # type = webdav
  # user = <user>
  # pass = <rclone obscure password>
  #
  # [gdrive]
  # type = drive
  # scope = drive
  # token = <json from `rclone authorize "drive"`>

  sops.secrets."rclone/conf" = { };

  my-services.rclone-syncs."taxes-sync" = {
    type = "bisync";
    source = "webdav:";
    sourceSubPath = "/Finance/Taxes";
    destination = "gdrive:";
    destSubPath = "/Taxes";
    rcloneConfig = config.sops.secrets."rclone/conf".path;
    interval = "daily";
    environment = {
      RCLONE_CONFIG_WEBDAV_URL = "http://localhost:4000/seafdav";
      RCLONE_CONFIG_WEBDAV_TYPE = "webdav";
      RCLONE_CONFIG_WEBDAV_VENDOR = "other";
    };
  };
}
