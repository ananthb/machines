{ pkgs, lib, ... }:

{
  options.my-scripts = {
    kopia-snapshot-backup = lib.mkOption {
      type = lib.types.package;
      default = null;
      description = ''
        It takes a bcachefs or btrfs subvolume (mounted under /srv or /var respectively)
        as its first argument.
        It creates a filesystem snapshot of the subvolume.
        It then creates a kopia snapshot of the new fs snapshot, backing up
        its contents to the hathi-backups GCS bucket.
      '';
    };
    kopia-backup = lib.mkOption {
      type = lib.types.package;
      default = null;
      description = ''
        It takes a directory as its first argument and creates a kopia snapshot of the directory,
        backing up its contents to the hathi-backups GCS bucket.
      '';
    };
    write-metrics = lib.mkOption {
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
        if [[ ! -d $1 ]] || [[ ! $1 =~ ^(/srv|/var)/ ]]; then
          printf '%s is not a directory under /srv or /var' "$1" >&2
          exit 1
        fi

        backup_source="$1"
        snapshot_target="$backup_source-$(date --utc --iso-8601=seconds)"
        if [[ $1 == "/srv/"* ]]; then
          # snapshot bcachefs subvolume
          if ! ${pkgs.bcachefs-tools}/bin/bcachefs subvolume snapshot -r \
            "$backup_source" "$snapshot_target"; then
            printf '%s might not be a bcachefs subvolume' "$backup_source" >&2
            exit 1
          fi
        else
          # snapshot btrfs subvolume
          if ! ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot -r \
            "$backup_source" "$snapshot_target"; then
            printf '%s might not be a btrfs subvolume' "$backup_source" >&2
            exit 1
          fi
        fi

        cleanup() {
          if [[ $backup_source == "/srv/"* ]]; then
            ${pkgs.bcachefs-tools}/bin/bcachefs subvolume delete \
              "$snapshot_target"
          else
            ${pkgs.btrfs-progs}/bin/btrfs subvolume delete \
              "$snapshot_target"
          fi
        }
        trap cleanup EXIT

        ${kopia-backup} "$snapshot_target"
      '';

      kopia-backup = pkgs.writeShellScript "kopia-backup" ''
        if [[ ! -d $1 ]]; then
          printf '%s is not a directory under /srv or /var' "$1" >&2
          exit 1
        fi

        source ${write-metrics}

        backup_target="$1"

        # Open remote kopia repository
        ${pkgs.kopia}/bin/kopia repository connect gcs \
          --bucket hathi-backups \
          --credentials-file /run/secrets/gcloud/service_accounts/kopia-hathi-backups.json \
          --password $(cat /run/secrets/kopia/gcs/hathi-backups)

        cleanup() {
          ${pkgs.kopia}/bin/kopia repository disconnect
        }
        trap cleanup EXIT

        ${pkgs.kopia}/bin/kopia snapshot create --parallel 4 "$backup_target"
        write_metrics kopia_backups_total "job=hathi-backups,instance=$backup_target" 1
      '';

      write-metrics = pkgs.writeShellScript "write-metrics" ''
        # Sends a metric to VictoriaMetrics in JSON format.
        # Usage: write_metrics <metric_name> <labels> <value>
        # <labels> should be a comma-separated string like "job=api,instance=server1"
        # Set VictoriaMetrics URL in the VM_URL environment variable (default: localhost:8428).
        write_metrics() {
          local metric_name="$1"
          local labels_str="$2"
          local value="$3"
          # Use environment variable for URL or default
          local vm_url="''${VM_URL:-http://localhost:8428}"

          if [[ $# -lt 3 ]]; then
            echo "Usage: write_metrics <metric_name> <labels> <value>"
            echo 'Example: write_metrics http_requests_total "job=httpie-test,instance=localhost" 15'
            return 1
          fi

          # Start building the JSON for the metric object
          local metric_json="{\"__name__\":\"$metric_name\""

          # Convert comma-separated labels to JSON key-value pairs
          if [ -n "$labels_str" ]; then
            IFS=',' read -ra labels_arr <<< "$labels_str"
            for label in "''${labels_arr[@]}"; do
              IFS='=' read -ra pair <<< "$label"
              metric_json="$metric_json, \"''${pair[0]}\":\"''${pair[1]}\""
            done
          fi
          metric_json="$metric_json}"

          # Get current timestamp in milliseconds
          local timestamp_ms="$(date +%s%3N)"

          # Construct the final payload
          local payload="{\"metric\":$metric_json, \"values\":[$value], \"timestamps\":[$timestamp_ms]}"
 
          # Send the data using httpie
          echo "$payload" | http POST "$vm_url/api/v1/write"
        }
      '';
    };
  };
}
