{
  lib,
  ...
}:

let
  authelia = "authelia-pie-o-my";
in

{

  services = {
    authelia.instances.pie-o-my = {
      enable = true;
      settings = {
        theme = "auto";
        authentication_backend.ldap = {
          address = "ldap://localhost:3890";
          base_dn = "dc=pie-o-my,dc=com";
          users_filter = "(&({username_attribute}={input})(objectClass=person))";
          groups_filter = "(member={dn})";
          user = "uid=authelia,ou=people,dc=pie-o-my,dc=com";
        };
        access_control = {
          default_policy = "deny";
          # We want this rule to be low priority so it doesn't override the others
          rules = lib.mkAfter [
            {
              domain = "*.pie-o-my.com";
              policy = "one_factor";
            }
          ];
        };
        storage.postgres = {
          address = "unix:///run/postgresql";
          database = authelia;
          username = authelia;
          # I'm using peer authentication, so this doesn't actually matter, but Authelia
          # complains if I don't have it.
          # https://github.com/authelia/authelia/discussions/7646
          password = authelia;
        };
        session = {
          redis.host = "/var/run/redis-authelia/redis.sock";
          cookies = [
            {
              domain = "pie-o-my.com";
              authelia_url = "https://auth.pie-o-my.com";
              # The period of time the user can be inactive for before the session is destroyed
              inactivity = "1M";
              # The period of time before the cookie expires and the session is destroyed
              expiration = "3M";
              # The period of time before the cookie expires and the session is destroyed
              # when the remember me box is checked
              remember_me = "1y";
            }
          ];
        };
        notifier.smtp = {
          address = "smtp://smtp.mailbox.org:587";
          username = "poperigby@mailbox.org";
          sender = "haddock@mailbox.org";
        };
        log.level = "info";
        identity_providers.oidc = {
          # https://www.authelia.com/integration/openid-connect/openid-connect-1.0-claims/#restore-functionality-prior-to-claims-parameter
          claims_policies = {
            karakeep.id_token = [ "email" ];
          };
          cors = {
            endpoints = [ "token" ];
            allowed_origins_from_client_redirect_uris = true;
          };
          authorization_policies.default = {
            default_policy = "one_factor";
            rules = [
              {
                policy = "deny";
                subject = "group:lldap_strict_readonly";
              }
            ];
          };
        };
      };
    };

    postgresql = {
      ensureDatabases = [ authelia ];
      ensureUsers = [
        {
          name = authelia;
          ensureDBOwnership = true;
        }
      ];
    };

    redis.servers.authelia = {
      enable = true;
    };
  };

  users.users.${authelia}.extraGroups = [ "redis-authelia" ];

  systemd.services.${authelia} =
    let
      dependencies = [
        "lldap.service"
        "postgresql.service"
        "redis-authelia.service"
      ];

    in
    {
      # Authelia requires LLDAP, PostgreSQL, and Redis to be running
      after = dependencies;
      requires = dependencies;
      # Required for templating
      serviceConfig.Environment = "X_AUTHELIA_CONFIG_FILTERS=template";
    };
}
