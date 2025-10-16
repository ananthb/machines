{ pkgs, lib, ... }:

{
  options.my-scripts = {
    kopia-snapshot-backup = lib.mkOption {
      type = lib.types.package;
      default = null;
      description = '''';
    };
    kopia-backup = lib.mkOption {
      type = lib.types.package;
      default = null;
      description = '''';
    };
    write-metric = lib.mkOption {
      type = lib.types.package;
      default = null;
      description = ''
        Sends a metric to VictoriaMetrics Remote Write API in JSON format.
      '';
    };
  };

  config = {
    my-scripts = rec {
      kopia-snapshot-backup = pkgs.writeShellScript "kopia-snapshot-backup" ''
        # Snapshot backs up a bcachefs/btrfs subvolume to the kopia hathi-backups GCS remote repository.
        # Usage: kopia-snapshot-backup <subvol-dir>
        # <subvol-dir> is a bcachefs or btrfs subvolume (mounted under /srv or /var respectively).
        # Creates a filesystem snapshot of <subvol-dir> and creates a kopia snapshot of that fs snapshot.

        usage() {
          echo 'Usage: kopia-snapshot-backup <subvol-dir>' >&2
          echo 'Example: kopia-snapshot-backup /srv/my-data/dir' >&2
        }

        if [[ $# -lt 1 ]]; then
          usage
          exit 1
        fi

        if [[ ! -d $1 ]] || [[ ! $1 =~ ^(/srv|/var)/ ]]; then
          printf '%s is not a directory under /srv or /var\n' "$1" >&2
          usage
          exit 1
        fi

        source ${write-metric}

        backup_source="$1"
        snapshot_target="$backup_source-$(date --utc --iso-8601=seconds)"

        write_metric kopia_backups_count "job=hathi-backups,instance=$backup_source,stage=fs_snapshot" 1
        trap '{
          write_metric kopia_backups_count "job=hathi-backups,instance=$backup_source,stage=fs_snapshot" 0
        }' EXIT

        if [[ $1 == "/srv/"* ]]; then
          # snapshot bcachefs subvolume
          if ! ${pkgs.bcachefs-tools}/bin/bcachefs subvolume snapshot -r \
            "$backup_source" "$snapshot_target"; then
            printf '%s might not be a bcachefs subvolume\n' "$backup_source" >&2
            usage
            exit 1
          fi
        else
          # snapshot btrfs subvolume
          if ! ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot -r \
            "$backup_source" "$snapshot_target"; then
            printf '%s might not be a btrfs subvolume\n' "$backup_source" >&2
            usage
            exit 1
          fi
        fi

        write_metric kopia_backups_count "job=hathi-backups,instance=$backup_source,stage=fs_snapshot" 0

        trap '{
          if [[ $backup_source == "/srv/"* ]]; then
            ${pkgs.bcachefs-tools}/bin/bcachefs subvolume delete \
              "$snapshot_target"
          else
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

        usage() {
          echo 'Usage: kopia-backup <directory> [<source>]' >&2
          echo 'Example: kopia-backup /tmp/my-app/data-snapshot /var/lib/my-app/data' >&2
        }

        if [[ $# -lt 1 ]]; then
          usage
          exit 1
        fi

        if [[ ! -d $1 ]]; then
          printf '%s is not a directory under /srv or /var\n' "$1" >&2
          usage
          exit 1
        fi

        source ${write-metric}

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
          --parallel 4 \
          --override-source "$source" \
          "$backup_target"
        write_metric kopia_backups_total "job=hathi-backups,instance=$source" 1
      '';

      write-metric = pkgs.writeShellScript "write-metric" ''
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
            --check-status \
            --timeout=1 \
            --ignore-stdin \
            POST "$vm_url/api/v1/import/prometheus" || true
        }
      '';
    };
  };
}
