{ trustedIPs, ... }:

{
  services.traefik = {
    enable = true;

    static.settings = {
      log = {
        level = "INFO";
      };

      accessLog = { };

      api.dashboard = true;

      metrics.prometheus = {
        entryPoint = "traefik_admin";
        addEntryPointsLabels = true;
        addRoutersLabels = true;
        addServicesLabels = true;
      };

      providers.file = {
        watch = true;
      };

      entryPoints.traefik_admin = {
        address = ":8080";
        forwardedHeaders.trustedIPs = trustedIPs;
      };
    };

    dynamic.settings = {
      http.routers.dashboard = {
        rule = "PathPrefix(`/`)";
        entryPoints = [ "traefik_admin" ];
        service = "api@internal";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
}
