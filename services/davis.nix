{
  config,
  options,
  ...
}:
let
  vs = config.vault-secrets.secrets;
in
{
  imports = [
    ./caddy.nix
  ];

  services.davis = {
    enable = true;
    adminPasswordFile = "${vs.davis}/admin_password";
    appSecretFile = "${vs.davis}/app_secret";
    database.driver = "postgresql";
    mail = {
      dsnFile = "${vs.davis}/mail-dsn";
      inviteFromAddress = "davis@kedi.dev";
    };
    nginx = null;
    poolConfig = options.services.davis.poolConfig.default // {
      "listen.owner" = "nobody";
      "listen.group" = "nobody";
    };
  };

  services.caddy.virtualHosts.":4101".extraConfig = ''
    reverse_proxy unix//run/phpfpm/davis.sock
  '';

  vault-secrets.secrets.davis = {
    services = [ "davis" ];
  };
}
