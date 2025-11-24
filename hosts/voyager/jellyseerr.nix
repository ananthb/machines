{ ... }:

{

  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "jellyseerr"
    ];
    ensureUsers = [

    ];
  };
}
