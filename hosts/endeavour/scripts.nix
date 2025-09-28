{ pkgs, lib, ... }:

{
  options.my-scripts.snapshot-backup = lib.mkOption {
    type = lib.types.package;
    default = null;
    description = ''
      Takes kopia snapshot backups of bcachefs or btrfs subvolumes mounted under
      /srv or /var mountpoints respectively.
      Creates a snapshot of subvolume /{srv,var}/subvol at /{srv,var}/subvol-$(current_date_time).
      Then creates a kopia snapshot of the newly created bcachefs subvolue in the gcs hathi-backups
      repository (Google Cloud Storage Bucket).
    '';
  };

  config = {
    my-scripts.snapshot-backup = pkgs.writeShellScript "snapshot-backup" ''
      #!/bin/bash

      set -euo pipefail

      if [[ ! -d "$1" ]] || [[ ! "$1" =~ ^(/srv|/var)/ ]]; then
      fi

      btrfs_snapshot=0
      bcachefs_snapshot=0
      if [[ $1 == "/srv/"* ]]; then
        bcachefs_snapshot=1
      elif [[ $1 == "/var/"* ]]; then
        btrfs_snapshot=1
      else
        printf '%s is not a directory under /srv or /var' "$1" >&2
        exit 1
      fi

      ${pkgs.kopia}/bin/kopia repository connect gcs \
        --bucket hathi-backups \
        --credentials-file /run/secrets/gcloud/service_accounts/kopia-hathi-backups.json \
        --password $(cat /run/secrets/kopia/gcs/hathi-backups)

      backup_timestamp=$(date --utc --iso-8601=seconds)

      if [[ $1 == "/srv/"* ]]; then
        # snapshot bcachefs subvolume
        if ! ${pkgs.bcachefs-tools}/bin/bcachefs subvolume snapshot -r \
          "$1" "$1-$backup_timestamp"; then
          printf '%s might not be a bcachefs subvolume' "$1" >&2
          exit 1
        fi
      else
        # snapshot btrfs subvolume
        if ! ${pkgs.btrfs-tools}/bin/btrfs subvolume snapshot -r \
          "$1" "$1-$backup_timestamp"; then
          printf '%s might not be a btrfs subvolume' "$1" >&2
          exit 1
        fi
      fi

      cleanup() {
        ${pkgs.kopia}/bin/kopia repository disconnect
        if [[ $1 == "/srv/"* ]]; then
          ${pkgs.bcachefs-tools}/bin/bcachefs subvolume delete \
            "$1-$backup_timestamp"
        else
          ${pkgs.btrfs-tools}/bin/btrfs subvolume delete \
            "$1-$backup_timestamp"
        fi
      }

      trap cleanup EXIT

      printf 'starting kopia snapshot of %s' "$1-$backup_timestamp"
      ${pkgs.kopia}/bin/kopia snapshot create --parallel 4 "$1-$backup_timestamp"

      printf 'backed up "%s" at %s\n' "$1" "$backup_timestamp"
    '';
  };
}
