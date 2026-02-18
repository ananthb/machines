{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:
let
  secureBootEnabled = config.boot.lanzaboote.enable or false;
  inherit (config.services.vault) tpmUnseal;
  unsealScript = pkgs.writeShellScript "vault-unseal-tpm" ''
    set -euo pipefail

    umask 0077
    tmpdir="$(mktemp -d /run/vault-unseal.XXXXXX)"
    trap 'rm -rf "$tmpdir"' EXIT

    for handle in ${lib.concatStringsSep " " tpmUnseal.handles}; do
      "${pkgs.tpm2-tools}/bin/tpm2_unseal" -c "$handle" -o "$tmpdir/unseal.key"
      unseal_key="$(cat "$tmpdir/unseal.key")"
      "${pkgs.vault}/bin/vault" operator unseal "$unseal_key"
    done
  '';
in
{
  options.services.vault.tpmUnseal = {
    enable = lib.mkEnableOption "TPM2-based boot-time unseal for Vault (OSS)";
    handles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "0x81000001"
        "0x81000002"
        "0x81000003"
      ];
      description = "TPM persistent object handles holding Vault unseal shares.";
    };
    pcrs = lib.mkOption {
      type = lib.types.str;
      default = if secureBootEnabled then "0,2,7" else "0,2";
      description = "PCRs used when sealing unseal shares to TPM (manual setup).";
    };
    vaultAddr = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:8200";
      description = "Vault address used by the unseal service.";
    };
  };

  config = {
    services.vault = {
      enable = true;
      address = "[::]:8200";
      storageBackend = "raft";
      storageConfig = ''
        node_id = "${hostname}"
      '';
      extraConfig = ''
        ui = true
        disable_mlock = true
        api_addr = "http://${hostname}:8200"
        cluster_addr = "http://${hostname}:8201"
      '';
    };

    # Default to enabling TPM unseal only when Secure Boot is on.
    services.vault.tpmUnseal.enable = lib.mkDefault secureBootEnabled;

    environment.systemPackages = lib.mkIf tpmUnseal.enable [
      pkgs.tpm2-tools
      pkgs.vault
    ];

    assertions = [
      {
        assertion = (!tpmUnseal.enable) || (tpmUnseal.handles != [ ]);
        message = "services.vault.tpmUnseal.enable is true but no TPM handles are configured.";
      }
    ];

    systemd.services.vault-unseal = lib.mkIf tpmUnseal.enable {
      description = "Unseal Vault via TPM2";
      after = [ "vault.service" ];
      wants = [ "vault.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "vault";
        Group = "vault";
        Environment = [
          "VAULT_ADDR=${tpmUnseal.vaultAddr}"
        ];
        ExecStart = [
          "${unsealScript}"
        ];
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/run" ];
      };
      wantedBy = [ "multi-user.target" ];
    };

    # Manual setup for TPM-bound unseal shares (OSS):
    # 1) Choose PCRs. When Secure Boot is enabled, use ${tpmUnseal.pcrs}
    #    (default: 0,2,7). Without Secure Boot, prefer a smaller PCR set.
    # 2) Create PCR policy: tpm2_createpolicy --policy-pcr -l sha256:${tpmUnseal.pcrs} -L /var/lib/vault/pcr.policy
    # 3) Create a primary key: tpm2_createprimary -C o -c /var/lib/vault/tpm.primary
    # 4) For each unseal share, seal and persist it to a handle in services.vault.tpmUnseal.handles:
    #    tpm2_create -C /var/lib/vault/tpm.primary -u /var/lib/vault/unsealX.pub -r /var/lib/vault/unsealX.priv \
    #      -L /var/lib/vault/pcr.policy -i /path/to/unseal_share_X
    #    tpm2_load -C /var/lib/vault/tpm.primary -u /var/lib/vault/unsealX.pub -r /var/lib/vault/unsealX.priv -c /var/lib/vault/unsealX.ctx
    #    tpm2_evictcontrol -C o -c /var/lib/vault/unsealX.ctx 0x8100000X
    # 5) Remove plaintext unseal share files after verifying a successful unseal.
  };
}
