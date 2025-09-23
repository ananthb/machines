{ pkgs, lib, ... }:

{
  options.my-scripts.srv-snapshot-backup = lib.mkOption {
    type = lib.types.package;
    default = null;
    description = ''
      Takes kopia snapshot backups of bcachefs subvolumes mounted under the /srv mountpoint.
      Creates a snapshot of subvolume /srv/subvol at /srv/subvol-$(current_date_time).
      Then creates a kopia snapshot of the newly created bcachefs subvolue in the gcs hathi-backups
      repository (Google Cloud Storage Bucket).
    '';
  };

  config = {
    my-scripts.srv-snapshot-backup = pkgs.writeShellScript "srv-snapshot-backup" ''
      #!/bin/bash

      set -euo pipefail

      backup_source_dir="/srv/$1"
      if [[ ! -d "$backup_source_dir" ]]; then
        printf '%s is not a directory' "$backup_source_dir" >&2
        exit 1
      fi

      ${pkgs.kopia}/bin/kopia repository connect gcs \
        --bucket hathi-backups \
        --credentials-file /run/secrets/gcloud/service_accounts/kopia-hathi-backups.json \
        --password $(cat /run/secrets/kopia/gcs/hathi-backups)

      backup_timestamp=$(date --utc --iso-8601=seconds)

      # Snapshot bcachefs subvolume
      if ! ${pkgs.bcachefs-tools}/bin/bcachefs subvolume snapshot -r \
        "$backup_source_dir" \
        "$backup_source_dir-$backup_timestamp"; then
        printf '%s might not be a bcachefs subvolume' "$backup_source_dir" >&2
        exit 1
      fi

      cleanup() {
        ${pkgs.kopia}/bin/kopia repository disconnect
        ${pkgs.bcachefs-tools}/bin/bcachefs subvolume delete \
          "$backup_source_dir-$backup_timestamp"
      }

      trap cleanup EXIT

      printf 'starting kopia snapshot of %s' "$backup_source_dir-$backup_timestamp"
      ${pkgs.kopia}/bin/kopia snapshot create --parallel 4 "$backup_source_dir-$backup_timestamp"

      printf 'backed up "%s" at %s\n' "$backup_source_dir" "$backup_timestamp"
    '';
  };
}
