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

      backup_source="$1"
      if [[ ! -d "$backup_source" ]] || [[ ! "$backup_source" =~ ^(/srv|/var)/ ]]; then
        printf '%s is not a directory under /srv or /var' "$backup_source" >&2
        exit 1
      fi

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

      # Open remote kopia repository
      ${pkgs.kopia}/bin/kopia repository connect gcs \
        --bucket hathi-backups \
        --credentials-file /run/secrets/gcloud/service_accounts/kopia-hathi-backups.json \
        --password $(cat /run/secrets/kopia/gcs/hathi-backups)

      cleanup() {
        ${pkgs.kopia}/bin/kopia repository disconnect
        if [[ $backup_source == "/srv/"* ]]; then
          ${pkgs.bcachefs-tools}/bin/bcachefs subvolume delete \
            "$snapshot_target"
        else
          ${pkgs.btrfs-progs}/bin/btrfs subvolume delete \
            "$snapshot_target"
        fi
      }

      trap cleanup EXIT

      ${pkgs.kopia}/bin/kopia snapshot create --parallel 4 "$snapshot_target"
    '';
  };
}
