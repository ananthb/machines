{
  config,
  pkgs,
  meta,
  ...
}:

{
  services.coder = {
    enable = true;
    accessUrl = "https://coder.kedi.dev";
    environmentFile = config.sops.templates."coder/env".path;
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "coder" ];
    ensureUsers = [
      {
        name = "coder";
        ensureDBOwnership = true;
      }
    ];
  };

  users.users.coder.extraGroups = [
    "podman"
    "kvm"
  ];

  security.sudo.extraRules = [
    {
      users = [ "coder" ];
      commands = [
        {
          command = "${pkgs.firecracker}/bin/jailer";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.firecracker}/bin/firecracker";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.iproute2}/bin/ip";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.iproute2}/bin/tc";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Enable IPv4 forwarding
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking = {
    # Create a bridge interface
    bridges."coder-br0".interfaces = [ ];
    interfaces."coder-br0".ipv4.addresses = [
      {
        address = "172.16.0.1";
        prefixLength = 24;
      }
    ];

    # Configure NAT
    nftables.enable = true;
    nftables.tables."nat" = {
      family = "ip";
      content = ''
        chain postrouting {
          type nat hook postrouting priority 100; policy accept;
          oifname "${meta.primaryInterface}" masquerade
        }
      '';
    };
  };

  environment.systemPackages = with pkgs; [
    firecracker
    bridge-utils
  ];

  sops.templates."coder/env" = {
    content = ''
      CODER_PG_CONNECTION_URL=postgresql://coder@/coder?host=/run/postgresql
      CODER_HTTP_ADDRESS=127.0.0.1:3000
      CODER_ACCESS_URL=https://coder.kedi.dev
      CODER_OIDC_ISSUER_URL=https://accounts.google.com
      CODER_OIDC_EMAIL_DOMAIN=
      CODER_OIDC_CLIENT_ID=${config.sops.placeholder."gcloud/oauth_self-hosted_clients/id"}
      CODER_OIDC_CLIENT_SECRET=${config.sops.placeholder."gcloud/oauth_self-hosted_clients/secret"}
      DOCKER_HOST=unix:///var/run/docker.sock
    '';
  };

  sops.secrets = {
    "gcloud/oauth_self-hosted_clients/id" = { };
    "gcloud/oauth_self-hosted_clients/secret" = { };
  };
}
