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
          type = mkOption {
            type = types.enum [
              "sync"
              "bisync"
            ];
            default = "sync";
            description = "Type of sync job: 'sync' (one-way) or 'bisync' (two-way)";
          };
          source = mkOption {
            type = types.str;
            description = "Source remote:path or local path";
          };
          sourceSubPath = mkOption {
            type = types.str;
            default = "";
            description = "Sub-path to append to source";
          };
          destination = mkOption {
            type = types.str;
            description = "Destination remote:path or local path";
          };
          destSubPath = mkOption {
            type = types.str;
            default = "";
            description = "Sub-path to append to destination";
          };
          checkAccess = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to perform access checks (create/delete test file)";
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
          excludePatterns = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Patterns to exclude from sync (passed to rclone --exclude)";
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
        inherit (job) environment;

        serviceConfig = {
          Type = "oneshot";
          User = job.user;
          # 12h timeout for large syncs
          TimeoutStartSec = "12h";
          # Create a cache directory for bisync state
          CacheDirectory = "rclone-sync-${name}";
          CacheDirectoryMode = "0700";
        };

        script = ''
          set -uo pipefail
          source ${config.my-scripts.shell-helpers}

          if [ ! -f "${job.rcloneConfig}" ]; then
            die "Rclone config not found at ${job.rcloneConfig}"
          fi

          # Set cache directory for bisync listings
          export XDG_CACHE_HOME="/var/cache/rclone-sync-${name}"

          # Construct full paths (using rclone syntax)
          FULL_SOURCE="${job.source}"
          if [ -n "${job.sourceSubPath}" ]; then
             clean_source="''${FULL_SOURCE%/}"
             clean_sub="${lib.strings.removePrefix "/" job.sourceSubPath}"
             FULL_SOURCE="''${clean_source}/''${clean_sub}"
          fi

          FULL_DEST="${job.destination}"
          if [ -n "${job.destSubPath}" ]; then
             clean_dest="''${FULL_DEST%/}"
             clean_sub_dest="${lib.strings.removePrefix "/" job.destSubPath}"
             FULL_DEST="''${clean_dest}/''${clean_sub_dest}"
          fi

          echo "Starting rclone job (${job.type}): ${name}"
          echo "Source: $FULL_SOURCE"
          echo "Destination: $FULL_DEST"

          write_metric rclone_sync_status "job=${name},stage=start,type=${job.type}" 1

          # Build exclude arguments
          EXCLUDE_ARGS=(${lib.concatMapStringsSep " " (p: "\"--exclude\" \"${p}\"") job.excludePatterns})

          if [ "${job.type}" = "bisync" ]; then
            BISYNC_ARGS=(
              "--config" "${job.rcloneConfig}"
              "--verbose"
              ${lib.optionalString job.checkAccess "\"--check-access\""}
              "--remove-empty-dirs"
              "''${EXCLUDE_ARGS[@]}"
            )

            if [ ! -d "$XDG_CACHE_HOME/rclone/bisync" ] || [ -z "$(ls -A "$XDG_CACHE_HOME/rclone/bisync")" ]; then
              echo "First run detected or cache empty. Using --resync."
              BISYNC_ARGS+=("--resync")
            fi

            TEMP_LOG=$(mktemp)
            trap 'rm -f "$TEMP_LOG"' EXIT

            if ${pkgs.rclone}/bin/rclone bisync \
              "''${BISYNC_ARGS[@]}" \
              "$FULL_SOURCE" "$FULL_DEST" 2>&1 | tee "$TEMP_LOG"; then
              
              echo "Bisync successful"
              write_metric rclone_sync_status "job=${name},stage=complete,type=${job.type}" 1
              write_metric rclone_sync_last_success_timestamp "job=${name}" "$(date +%s)"
            else
              EXIT_CODE=$?
              echo "Bisync failed with code $EXIT_CODE"

              if grep -q "Must run --resync to recover" "$TEMP_LOG"; then
                 echo "Critical state error detected. Attempting auto-recovery with --resync..."
                 BISYNC_ARGS+=("--resync")
                 if ${pkgs.rclone}/bin/rclone bisync \
                    "''${BISYNC_ARGS[@]}" \
                    "$FULL_SOURCE" "$FULL_DEST"; then
                     echo "Recovery bisync successful"
                     write_metric rclone_sync_status "job=${name},stage=complete,type=${job.type}" 1
                     write_metric rclone_sync_last_success_timestamp "job=${name}" "$(date +%s)"
                 else
                     echo "Recovery bisync failed"
                     write_metric rclone_sync_status "job=${name},stage=error,type=${job.type}" 1
                     die "Rclone bisync failed even after resync attempt"
                 fi
              else
                 echo "Bisync failed"
                 write_metric rclone_sync_status "job=${name},stage=error,type=${job.type}" 1
                 die "Rclone bisync failed"
              fi
            fi

          else
            # Normal sync
            if ${pkgs.rclone}/bin/rclone sync \
              --config "${job.rcloneConfig}" \
              --verbose \
              --use-mmap \
              --transfers 4 \
              --checkers 8 \
              "''${EXCLUDE_ARGS[@]}" \
              "$FULL_SOURCE" "$FULL_DEST"; then
              
              echo "Sync successful"
              write_metric rclone_sync_status "job=${name},stage=complete,type=${job.type}" 1
              write_metric rclone_sync_last_success_timestamp "job=${name}" "$(date +%s)"
            else
              echo "Sync failed"
              write_metric rclone_sync_status "job=${name},stage=error,type=${job.type}" 1
              die "Rclone sync failed"
            fi
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
