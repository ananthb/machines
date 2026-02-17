{ config, ... }:
let
  vs = config.vault-secrets.secrets;
in
{
  my-services.rclone-syncs = {
    "ananth-finance" = {
      type = "bisync";
      source = "seafile:";
      sourceSubPath = "/Finance";
      destination = "gdrive:";
      destSubPath = "/Finance";
      checkAccess = false;
      sizeOnly = true;
      rcloneConfig = "${vs.rclone-ananth}/config";
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
      sizeOnly = true;
      rcloneConfig = "${vs.rclone-bhaskar}/config";
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
      sizeOnly = true;
      rcloneConfig = "${vs.rclone-bhaskar}/config";
      interval = "*:0/5";
      environment = {
        RCLONE_CONFIG_SEAFILE_URL = "http://localhost:4444/seafdav";
        RCLONE_CONFIG_SEAFILE_TYPE = "webdav";
        RCLONE_CONFIG_SEAFILE_VENDOR = "other";
      };
    };
  };

  vault-secrets.secrets.rclone-ananth = {
    services = [ "rclone-sync-ananth-finance" ];
  };

  vault-secrets.secrets.rclone-bhaskar = {
    services = [
      "rclone-sync-bhaskar-documents"
      "rclone-sync-bhaskar-family-library"
    ];
  };
}
