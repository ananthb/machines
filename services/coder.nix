{ config, pkgs, ... }:
{
  services.coder = {
    enable = true;
    accessUrl = "https://coder.kedi.dev";
    listenAddress = "[::1]:3030";
    environment = {
      extra = {
        CODER_OAUTH2_GITHUB_ALLOW_SIGNUPS = "true";
        CODER_OAUTH2_GITHUB_ALLOWED_ORGS = "kedi-code";
        DOCKER_HOST = "unix:///run/podman/podman.sock";
      };
      file = config.sops.templates."coder/env".path;
    };
  };

  users.users.coder.extraGroups = [
    "podman"
    "kvm"
  ];

  systemd.services.coder.path = with pkgs; [
    firecracker
    iproute2
    iptables
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
          command = "${pkgs.iptables}/bin/iptables";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  sops.templates."coder/env" = {
    content = ''
      CODER_OAUTH2_GITHUB_CLIENT_ID=${config.sops.placeholder."github/oauth/kedi-coder/id"}
      CODER_OAUTH2_GITHUB_CLIENT_SECRET=${config.sops.placeholder."github/oauth/kedi-coder/secret"}
    '';
  };

  sops.secrets = {
    "github/oauth/kedi-coder/id" = { };
    "github/oauth/kedi-coder/secret" = { };
  };
}
