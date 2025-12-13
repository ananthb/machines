{ pkgs-wip-traefik-plugins, trustedIPs, ... }:

{

  imports = [
    (pkgs-wip-traefik-plugins + "/nixos/modules/services/web-servers/traefik.nix")
  ];

  services.traefik = {
    enable = true;
    package = pkgs-wip-traefik-plugins.traefik;

    static.config = {
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

    dynamic.config = {
      http.routers.dashboard = {
        rule = "PathPrefix(`/`)";
        entryPoints = [ "traefik_admin" ];
        service = "api@internal";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
}
