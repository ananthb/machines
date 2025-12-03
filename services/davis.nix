{
  config,
  inputs,
  lib,
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
      "listen.owner" = "caddy";
      "listen.group" = "caddy";
    };
  };

  services.caddy.virtualHosts.":4000".extraConfig = ''
    reverse_proxy unix//run/phpfpm/davis.sock
  '';

  networking.firewall.allowedTCPPorts = [ 4000 ];

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
