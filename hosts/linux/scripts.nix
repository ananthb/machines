{ pkgs, lib, ... }:

{
  options.my-scripts = {
    kopia-snapshot-backup = lib.mkOption {
      type = lib.types.package;
      default = null;
      description = ''
        Takes snapshot backups of filesystem subvolumes to remote storage.
        Supports btrfs and bcachefs subvolumes.
      '';
    };
    kopia-backup = lib.mkOption {
      type = lib.types.package;
      default = null;
      description = ''
        Takes snapshot backups of regular directories to remote storage.
      '';
    };
    shell-helpers = lib.mkOption {
      type = lib.types.package;
      default = null;
      description = "Shell helpers for handling errors and writing metrics.";
    };
  };

  config = {
    my-scripts = rec {
      kopia-snapshot-backup = pkgs.writeShellScript "kopia-snapshot-backup" ''
        # Snapshot backs up a bcachefs/btrfs subvolume to the kopia hathi-backups GCS remote repository.
        # Usage: kopia-snapshot-backup <subvol-dir>
        # <subvol-dir> is a bcachefs or btrfs subvolume.
        # Creates a filesystem snapshot of <subvol-dir> and creates a kopia snapshot of that fs snapshot.

        set -uo pipefail

        source ${shell-helpers}

        usage() {
          echo 'Usage: kopia-snapshot-backup <subvol-dir>' >&2
          echo 'Example: kopia-snapshot-backup /my/data/dir' >&2
        }

        if [[ $# -lt 1 ]]; then
          usage
          exit 1
        fi

        backup_source="$1"
        backup_fs="$(stat -f -c %T $1)"

        if [[ $backup_fs != "bcachefs" && $backup_fs != "btrfs" ]]; then
          die "unsupported fs $backup_fs"
        fi

        snapshot_target="$backup_source-$(date --utc --iso-8601=seconds)"

        write_metric kopia_backups_count "job=hathi-backups,instance=$backup_source,stage=fs_snapshot" 1
        trap '{
          write_metric kopia_backups_count "job=hathi-backups,instance=$backup_source,stage=fs_snapshot" 0
        }' EXIT

        if [[ $backup_fs == "bcachefs" ]]; then
          # snapshot bcachefs subvolume
          if ! ${pkgs.bcachefs-tools}/bin/bcachefs subvolume snapshot -r \
            "$backup_source" "$snapshot_target"; then
            die "$backup_source might not be a bcachefs subvolume"
          fi
        elif [[ $backup_fs == "btrfs" ]]; then
          # snapshot btrfs subvolume
          if ! ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot -r \
            "$backup_source" "$snapshot_target"; then
            die "$backup_source might not be a btrfs subvolume"
          fi
        fi

        write_metric kopia_backups_count "job=hathi-backups,instance=$backup_source,stage=fs_snapshot" 0

        trap '{
          if [[ $backup_fs == "bcachefs" ]]; then
            ${pkgs.bcachefs-tools}/bin/bcachefs subvolume delete \
              "$snapshot_target"
          elif [[ $backup_fs == "btrfs" ]]; then
            ${pkgs.btrfs-progs}/bin/btrfs subvolume delete \
              "$snapshot_target"
          fi
        }' EXIT

        ${kopia-backup} "$snapshot_target" "$backup_source"
      '';

      kopia-backup = pkgs.writeShellScript "kopia-backup" ''
        # Backs up a directory to the kopia hathi-backups GCS remote repository.
        # Usage: kopia-backup <directory> [<source>]
        # <directory> is the directory to back up.
        # <source> is an optional value (default: <directory>) that overrides the kopia snapshot source directory.

        set -uo pipefail

        source ${shell-helpers}

        usage() {
          echo 'Usage: kopia-backup <directory> [<source>]' >&2
          echo 'Example: kopia-backup /tmp/my-app/data-snapshot /var/lib/my-app/data' >&2
        }

        if [[ $# -lt 1 ]]; then
          usage
          exit 1
        fi

        backup_target="$1"
        source="''${2:-$1}"

        write_metric kopia_backups_count "job=hathi-backups,instance=$source,stage=kopia_connect" 1
        trap '{
          write_metric kopia_backups_count "job=hathi-backups,instance=$source,stage=kopia_connect" 0
        }' EXIT

        # Open remote kopia repository
        ${pkgs.kopia}/bin/kopia repository connect gcs \
          --bucket hathi-backups \
          --credentials-file /run/secrets/gcloud/service_accounts/kopia-hathi-backups.json \
          --password $(cat /run/secrets/kopia/gcs/hathi-backups)

        write_metric kopia_backups_count "job=hathi-backups,instance=$source,stage=kopia_connect" 0

        trap '{
          ${pkgs.kopia}/bin/kopia repository disconnect
          write_metric kopia_backups_count "job=hathi-backups,instance=$source,stage=kopia_snapshot" 0
        }' EXIT

        write_metric kopia_backups_count "job=hathi-backups,instance=$source,stage=kopia_snapshot" 1
        ${pkgs.kopia}/bin/kopia snapshot create \
          --disable-color \
          --no-progress \
          --parallel 10 \
          --override-source "$source" \
          "$backup_target"
        write_metric kopia_backups_total "job=hathi-backups,instance=$source" 1
      '';

      shell-helpers = pkgs.writeShellScript "shell-helpers" ''
        # Usage: die "Error message here" [optional_exit_code]
        die() {
          local message="$1"
          local code="''${2:-1}"
          echo "Error: $message" >&2
          exit "$code"
        }

        # Sends a metric to VictoriaMetrics in JSON format.
        # Usage: write_metrics <metric_name> <labels> <value>
        # <labels> should be a comma-separated string like "job=api,instance=server1"
        # VM_URL environment variable (default: http://voyager:8428) selects
        # the VictoriaMetrics endpoint to send metrics to.
        write_metric() {
          local metric_name="$1"
          local labels_str="$2"
          local value="$3"
          # Use environment variable for URL or default
          local vm_url="''${VM_URL:-http://voyager:8428}"

          if [[ $# -lt 3 ]]; then
            echo 'Usage: write_metrics <metric_name> <labels> <value>' >&2
            echo 'Example: write_metrics http_requests_total "job=httpie-test,instance=localhost" 15' >&2
            exit 1
          fi

          local prom_labels=""
          if [ -n "$labels_str" ]; then
            # Convert comma-separated "key=value" to Prometheus "{key=\"value\",...}" format
            prom_labels="{"
            IFS=',' read -ra labels_arr <<< "$labels_str"
            for i in "''${!labels_arr[@]}"; do
              label="''${labels_arr[$i]}"
              IFS='=' read -ra pair <<< "$label"
              prom_labels+="''${pair[0]}=\"''${pair[1]}\""
              # Add a comma if it's not the last label
              if [[ $i -lt $((''${#labels_arr[@]} - 1)) ]]; then
                prom_labels+=","
              fi
            done
            prom_labels+="}"
          fi

          # Get current timestamp in milliseconds
          local timestamp_ms="$(date +%s%3N)"

          # Construct the Prometheus text format line
          local line="''${metric_name}''${prom_labels} ''${value} ''${timestamp_ms}"

          # Send the data using httpie to the prometheus write endpoint
          printf 'Sending line to %s: %s\n' "$vm_url" "$line" >&2

          # Send the data using httpie, ignoring errors
          echo "$line" | ${pkgs.httpie}/bin/http \
            --quiet \
            --timeout=1 \
            --ignore-stdin \
            post "$vm_url/api/v1/import/prometheus" || true
        }
      '';
    };
  };
}
