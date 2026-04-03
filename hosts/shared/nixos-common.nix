# Shared NixOS configuration for all NixOS hosts (local and garnix).
# Provides: sops-nix + vault-secrets wiring, quadlet, kedi-target,
# systemd hardening, journald limits, firewall defaults.
{
  config,
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.vault-secrets.nixosModules.vault-secrets
    inputs.quadlet-nix.nixosModules.quadlet
    ./nix-settings.nix
    ../../lib/kedi-target.nix
  ];

  sops.useSystemdActivation = true;

  sops.secrets =
    lib.mapAttrs' (
      name: value: let
        user = value.user or "root";
        group = value.group or "root";
        mode =
          if user != "root" || group != "root"
          then "0440"
          else "0400";
      in
        lib.nameValuePair "approles/${name}" {
          owner = user;
          inherit group mode;
        }
    )
    config.vault-secrets.secrets;

  vault-secrets.vaultPrefix = lib.mkDefault "kv/services";

  # Wire vault-secrets services to sops
  systemd.services = lib.mkMerge [
    (lib.mapAttrs' (
        name: _value:
          lib.nameValuePair "${name}-secrets" {
            requires = ["sops-install-secrets.service"];
            after = ["sops-install-secrets.service"];
            serviceConfig.EnvironmentFile = lib.mkForce config.sops.secrets."approles/${name}".path;
          }
      )
      config.vault-secrets.secrets)
    (lib.mapAttrs' (
        name: value:
          lib.nameValuePair "${name}-secrets" {
            serviceConfig.UMask = lib.mkIf (value.group != "root" && value.group != "nogroup") (
              lib.mkForce "0027"
            );
          }
      )
      config.vault-secrets.secrets)
  ];

  # Disable NixOS documentation generation on servers.
  documentation.nixos.enable = lib.mkDefault false;

  systemd = {
    enableEmergencyMode = false;

    # Enable systemd-oomd for memory pressure management
    oomd = {
      enable = true;
      enableRootSlice = true;
      enableUserSlices = true;
      enableSystemSlice = true;
    };
  };

  # Journald size limits
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    RuntimeMaxUse=100M
  '';

  networking.firewall = {
    enable = true;
    allowPing = true;
  };
}
