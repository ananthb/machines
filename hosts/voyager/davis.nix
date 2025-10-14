{
  config,
  inputs,
  lib,
  pkgs-unstable,
  ...
}:
{

  imports = [
    {
      disabledModules = ["services/web-apps/davis.nix"];
    }

    "${inputs.nixpkgs-unstable}/nixos/modules/services/web-apps/davis.nix"
  ];

  services.davis = {
    enable = true;
    package = pkgs-unstable.davis;
    adminPasswordFile = config.sops.secrets."davis/admin_password".path;
    appSecretFile = config.sops.secrets."davis/app_secret".path;
    database = {
      driver = "postgresql";
    };
    mail = {
      dsnFile = config.sops.templates."davis/mail-dsn".path;
      inviteFromAddress = "davis@kedi.dev";
    };
    nginx = lib.mkForce null;
  };

  services.tsnsrv.services.dav = {
    funnel = true;
    urlParts.port = 8080;
    upstreamUnixAddr = "/run/php-fpm.sock";
  };

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
