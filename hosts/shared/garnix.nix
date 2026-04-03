# Shared configuration for garnix-hosted NixOS servers.
# Provides: garnix module, sops/vault wiring, tailscale, openssh, kopia backups.
{
  config,
  garnix-lib,
  ...
}: {
  imports = [
    garnix-lib.nixosModules.garnix
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

  users.users.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINu7u4V6khhhUvepvptel86DN3XMCwZVdQe/7P6WW1KmAAAAFXNzaDphbmFudGhzLXNzaC1rZXktMQ== ananth@yubikey-5c"
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIFCVZPWg3DVxjuORNKJnjaRSPoZ4nYnzM070q0fIeM32AAAAG3NzaDphbmFudGhzLXNzaC1rZXktNWMtbmFubw== ananth@yubikey-5c-nano"
  ];
}
