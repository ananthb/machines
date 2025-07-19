{
  config,
  ...
}:

{
  services = {
    postgresql = {
      ensureDatabases = [
        "lldap"
      ];
      ensureUsers = [
        {
          name = "lldap";
          ensureDBOwnership = true;
        }
      ];
    };

    lldap = {
      enable = true;
      settings = {
        ldap_base_dn = "dc=pie-o-my,dc=com";
        ldap_user_email = "admin@pie-o-my.com";
        database_url = "postgresql://lldap@localhost/lldap?host=/run/postgresql";
      };
      environment = {
        LLDAP_JWT_SECRET_FILE = config.sops.secrets."lldap/jwt_secret".path;
        LLDAP_KEY_SEED_FILE = config.sops.secrets."lldap/key_seed".path;
        LLDAP_LDAP_USER_PASS_FILE = config.sops.secrets."lldap/admin_password".path;
      };
    };
  };

  systemd.services.lldap =
    let
      dependencies = [
        "postgresql.service"
      ];
    in
    {
      # LLDAP requires PostgreSQL to be running
      after = dependencies;
      requires = dependencies;
    };

  sops.secrets = {
    "lldap/jwt_secret".mode = "0444";
    "lldap/key_seed".mode = "0444";
    "lldap/admin_password".mode = "0444";
  };
}
