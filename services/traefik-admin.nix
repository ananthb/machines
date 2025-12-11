{ trustedIPs, ... }:

{
  services.traefik = {
    enable = true;

    staticConfigOptions = {
      api.dashboard = true;

      metrics.prometheus = {
        entryPoint = "traefik_admin";
        addEntryPointsLabels = true;
        addRoutersLabels = true;
        addServicesLabels = true;
      };

      entryPoints.traefik_admin = {
        address = ":8080";
        forwardedHeaders.trustedIPs = trustedIPs;
      };
    };

    dynamicConfigOptions = {
      http.routers.dashboard = {
        rule = "PathPrefix(`/`)";
        entryPoints = [ "traefik_admin" ];
        service = "api@internal";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
}
