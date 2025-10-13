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
  };

  config = {
    my-scripts = rec {
      kopia-snapshot-backup = pkgs.writeShellScript "kopia-snapshot-backup" ''
        #!/bin/bash

        set -euo pipefail

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
      '';
    };
  };
}
