{ config, ... }:
{
  my-services.rclone-syncs = {
    "ananth-finance" = {
      type = "bisync";
      source = "seafile:";
      sourceSubPath = "/Finance";
      destination = "gdrive:";
      destSubPath = "/Finance";
      checkAccess = false;
      rcloneConfig = config.sops.secrets."rclone/ananth".path;
      interval = "*:0/5";
      environment = {
        RCLONE_CONFIG_SEAFILE_URL = "http://localhost:4444/seafdav";
        RCLONE_CONFIG_SEAFILE_TYPE = "webdav";
        RCLONE_CONFIG_SEAFILE_VENDOR = "other";
      };
    };

    "bhaskar-documents" = {
      type = "bisync";
      source = "seafile:";
      sourceSubPath = "/Documents";
      destination = "gdrive:";
      destSubPath = "/Documents";
      checkAccess = false;
      rcloneConfig = config.sops.secrets."rclone/bhaskar".path;
      interval = "*:0/5";
      environment = {
        RCLONE_CONFIG_SEAFILE_URL = "http://localhost:4444/seafdav";
        RCLONE_CONFIG_SEAFILE_TYPE = "webdav";
        RCLONE_CONFIG_SEAFILE_VENDOR = "other";
      };
    };

    "bhaskar-family-library" = {
      type = "bisync";
      source = "seafile:";
      sourceSubPath = "/Family Library";
      destination = "gdrive:";
      destSubPath = "/Reference";
      checkAccess = false;
      rcloneConfig = config.sops.secrets."rclone/bhaskar".path;
      interval = "*:0/5";
      environment = {
        RCLONE_CONFIG_SEAFILE_URL = "http://localhost:4444/seafdav";
        RCLONE_CONFIG_SEAFILE_TYPE = "webdav";
        RCLONE_CONFIG_SEAFILE_VENDOR = "other";
      };
    };
  };

  sops.secrets = {
    "rclone/ananth" = { };
    "rclone/bhaskar" = { };
  };
}
