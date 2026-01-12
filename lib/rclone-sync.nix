{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types;
  cfg = config.my-services.rclone-syncs;
in
{
  options.my-services.rclone-syncs = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          source = mkOption {
            type = types.str;
            description = "Source remote:path or local path";
          };
          destination = mkOption {
            type = types.str;
            description = "Destination remote:path or local path";
          };
          rcloneConfig = mkOption {
            type = types.path;
            description = "Path to rclone.conf file (usually a sops secret)";
          };
          interval = mkOption {
            type = types.str;
            default = "daily";
            description = "Systemd OnCalendar interval";
          };
          user = mkOption {
            type = types.str;
            default = "root";
            description = "User to run the sync job as";
          };
          environment = mkOption {
            type = types.attrsOf types.str;
            default = { };
            description = "Environment variables for the sync job";
          };
        };
      }
    );
    default = { };
    description = "Rclone sync jobs";
  };

  config = {
    systemd.services = lib.mapAttrs' (name: job: {
      name = "rclone-sync-${name}";
      value = {
        description = "Rclone sync job: ${name}";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment = job.environment;

        serviceConfig = {
          Type = "oneshot";
          User = job.user;
          # 12h timeout for large syncs
          TimeoutStartSec = "12h";
        };

        script = ''
          set -uo pipefail
          source ${config.my-scripts.shell-helpers}

          # Ensure rclone config exists
          if [ ! -f "${job.rcloneConfig}" ]; then
            die "Rclone config not found at ${job.rcloneConfig}"
          fi

          echo "Starting rclone sync: ${name}"
          echo "Source: ${job.source}"
          echo "Destination: ${job.destination}"

          write_metric rclone_sync_status "job=${name},stage=start" 1

          if ${pkgs.rclone}/bin/rclone sync \
            --config "${job.rcloneConfig}" \
            --verbose \
            --use-mmap \
            --transfers 4 \
            --checkers 8 \
            "${job.source}" "${job.destination}"; then
            
            echo "Sync successful"
            write_metric rclone_sync_status "job=${name},stage=complete" 1
            write_metric rclone_sync_last_success_timestamp "job=${name}" "$(date +%s)"
          else
            echo "Sync failed"
            write_metric rclone_sync_status "job=${name},stage=error" 1
            die "Rclone sync failed"
          fi
        '';
      };
    }) cfg;

    systemd.timers = lib.mapAttrs' (name: job: {
      name = "rclone-sync-${name}";
      value = {
        timerConfig = {
          OnCalendar = job.interval;
          Persistent = true;
          RandomizedDelaySec = "15m";
        };
        wantedBy = [ "timers.target" ];
      };
    }) cfg;
  };
}
