{ ... }:

{
  services.jellyseerr.enable = true;

  systemd.services.jellyseerr.environment = {
    DB_TYPE = "postgres";
    DB_SOCKET_PATH = "/var/run/postgresql";
    DB_USER = "jellyseerr";
    DB_NAME = "jellyseerr";
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "jellyseerr"
    ];
    ensureUsers = [
      {
        name = "jellyseerr";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };
}
