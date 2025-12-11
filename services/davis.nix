{
  config,
  options,
  ...
}:
{
  services.davis = {
    enable = true;
    adminPasswordFile = config.sops.secrets."davis/admin_password".path;
    appSecretFile = config.sops.secrets."davis/app_secret".path;
    database.driver = "postgresql";
    mail = {
      dsnFile = config.sops.templates."davis/mail-dsn".path;
      inviteFromAddress = "davis@kedi.dev";
    };
    nginx = null;
    poolConfig = options.services.davis.poolConfig.default // {
      "listen.owner" = "nobody";
      "listen.group" = "nobody";
    };
  };

  services.traefik = {
    enable = true;

    staticConfigOptions = {
      entryPoints = {
        davis = {
          address = ":4101";
        };
      };
    };

    dynamicConfigOptions = {
      http = {
        routers.davis-router = {
          rule = "PathPrefix(`/`)";
          entryPoints = [ "davis" ];
          service = "davis-service";
        };

        services.davis-service.loadBalancer.servers = [
          { url = "unix:///run/phpfpm/davis.sock"; }
        ];
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 4101 ];

  sops.secrets = {
    "davis/admin_password" = { };
    "davis/app_secret" = { };
  };

  sops.templates."davis/mail-dsn" = {
    content = ''
      smtp://${config.sops.placeholder."email/smtp/username"}:${
        config.sops.placeholder."email/smtp/password"
      }@${config.sops.placeholder."email/smtp/host"}:587
    '';
  };
}
