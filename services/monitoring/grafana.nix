{ config, ... }:
{

  imports = [
    ./postgres.nix
  ];

  services = {
    grafana = {
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
          domain = "metrics.kedi.dev";
          root_url = "https://metrics.kedi.dev";
        };

        smtp = {
          enabled = true;
          user = "$__file{${config.sops.secrets."email/smtp/username".path}}";
          password = "$__file{${config.sops.secrets."email/smtp/password".path}}";
          host = "$__file{${config.sops.secrets."email/smtp/host".path}}:587";
          from_address = "$__file{${config.sops.secrets."email/from/grafana".path}}";
          startTLS_policy = "MandatoryStartTLS";
        };

        "auth.google" = {
          enabled = true;
          client_id = "$__file{${config.sops.secrets."gcloud/oauth/self-hosted_clients/id".path}}";
          client_secret = "$__file{${config.sops.secrets."gcloud/oauth/self-hosted_clients/secret".path}}";
          allow_sign_up = true;
          auto_login = true;
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

    postgresql = {
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
  };

  networking.firewall.allowedTCPPorts = [ 3000 ];

  sops.secrets = {
    "email/from/grafana".owner = config.users.users.grafana.name;
    "email/smtp/host".owner = config.users.users.grafana.name;
    "email/smtp/username".owner = config.users.users.grafana.name;
    "email/smtp/password".owner = config.users.users.grafana.name;
    # Shared OAuth secrets - mode 0444 so multiple services can read
    "gcloud/oauth/self-hosted_clients/id".mode = "0444";
    "gcloud/oauth/self-hosted_clients/secret".mode = "0444";
  };
}
