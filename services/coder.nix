{ config, pkgs, ... }:
let
  vs = config.vault-secrets.secrets;
in
{
  imports = [
    ((import ../lib/caddy-ddns.nix).mkCaddyDdns { domains = [ "*.coder" ]; })
  ];

  services.coder = {
    enable = true;
    accessUrl = "https://coder.kedi.dev";
    wildcardAccessUrl = "*.coder.kedi.dev";
    listenAddress = "[::1]:3030";
    environment = {
      extra = {
        CODER_OAUTH2_GITHUB_ALLOW_SIGNUPS = "true";
        CODER_OAUTH2_GITHUB_ALLOWED_ORGS = "kedi-code";
        DOCKER_HOST = "unix:///run/podman/podman.sock";
        CODER_PROMETHEUS_ADDRESS = "[::]:2112";
      };
      file = "${vs.coder}/environment";
    };
  };

  my-services.kediTargets.coder = true;

  services.caddy.virtualHosts = {
    "*.coder.kedi.dev" = {
      extraConfig = ''
        tls {
          dns cloudflare {$CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy [::1]:3030
      '';
    };
  };

  users.users.coder.extraGroups = [
    "podman"
    "kvm"
  ];

  systemd.services.coder = {
    partOf = [ "kedi.target" ];
    path = with pkgs; [
      firecracker
      iproute2
      iptables
    ];
  };

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

  vault-secrets.secrets.coder = {
    services = [ "coder" ];
  };

}
