{ config, inputs, ... }:
{

  imports = [
    inputs.tsnsrv.nixosModules.default
  ];

  services.grafana = {
    enable = true;
    settings = {
      database = {
        type = "postgres";
        host = "/run/postgresql";
        name = "grafana";
        user = "grafana";
      };

      server = {
        http_addr = "::";
        domain = "$__file{${config.sops.templates."fqdns/grafana.txt".path}}";
      };

      smtp = {
        enabled = true;
        user = "$__file{${config.sops.secrets."email/smtp/username".path}}";
        password = "$__file{${config.sops.secrets."email/smtp/password".path}}";
        host = "$__file{${config.sops.secrets."email/smtp/host".path}}:587";
        from_address = "$__file{${config.sops.secrets."email/from/grafana".path}}";
        startTLS_policy = "MandatoryStartTLS";
      };
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          url = "http://localhost:8428";
          name = "VictoraMetrics";
          type = "prometheus";
          jsonData = {
            httpMethod = "POST";
            manageAlerts = true;
          };
        }
      ];
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "grafana" ];
    ensureUsers = [
      {
        name = "grafana";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };

  services.tsnsrv = {
    enable = true;

    defaults.authKeyPath = config.sops.secrets."tailscale_api/auth_key".path;
    defaults.urlParts.host = "localhost";

    services.mon = {
      funnel = true;
      urlParts.port = 3000;
    };
  };

  systemd.services.grafana.environment = {
    GF_AUTH_DISABLE_LOGIN_FORM = "true";
    GF_AUTH_BASIC_ENABLED = "false";
    GF_AUTH_PROXY_ENABLED = "true";
    GF_AUTH_PROXY_HEADER_NAME = "X-Tailscale-User-LoginName";
    GF_AUTH_PROXY_HEADER_PROPERTY = "username";
    GF_AUTH_PROXY_AUTO_SIGN_UP = "false";
    GF_AUTH_PROXY_SYNC_TTL = "60";
    GF_AUTH_PROXY_WHITELIST = "::1";
    GF_AUTH_PROXY_HEADERS = "Name:X-Tailscale-User-DisplayName";
    GF_AUTH_PROXY_ENABLE_LOGIN_TOKEN = "true";
  };

  sops.secrets = {
    "email/from/grafana".owner = config.users.users.grafana.name;
    "email/smtp/host".owner = config.users.users.grafana.name;
    "email/smtp/username".owner = config.users.users.grafana.name;
    "email/smtp/password".owner = config.users.users.grafana.name;
    "tailscale_api/auth_key" = { };
    "tailscale_api/tailnet" = { };
  };

  sops.templates."fqdns/grafana.txt" = {
    owner = config.users.users.grafana.name;
    content = "mon.${config.sops.placeholder."tailscale_api/tailnet"}";
  };
}
