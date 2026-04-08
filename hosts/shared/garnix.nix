# Shared configuration for garnix-hosted NixOS servers.
# Provides: garnix module, sops/vault wiring, tailscale, openssh, kopia backups.
{
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.garnix-lib.nixosModules.garnix
    ./nixos-common.nix
    ../../lib/scripts.nix
  ];

  garnix.server.enable = true;

  sops.age.keyFile = "/var/garnix/keys/repo-key";

  vault-secrets.vaultAddress = "http://endeavour:8200";

  services = {
    tailscale.enable = true;

    openssh = {
      enable = true;
      settings.PermitRootLogin = "prohibit-password";
      settings.PasswordAuthentication = false;
    };
  };

  networking.firewall = {
    trustedInterfaces = [config.services.tailscale.interfaceName];
    allowedTCPPorts = [22];
  };

  environment.systemPackages = [
    config.services.tailscale.package
  ];

  users.users.root.openssh.authorizedKeys.keys = import ../../lib/ssh-keys.nix;
}
