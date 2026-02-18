{
  config,
  lib,
  outputs,
  ...
}:
let
  inherit (lib)
    mapAttrsToList
    flatten
    concatMap
    optionals
    hasAttr
    ;

  vs = config.vault-secrets.secrets;

  # Helper functions to check for enabled services/exporters
  hasService = c: name: hasAttr name c.services && c.services.${name}.enable or false;
  hasExporter =
    c: name:
    hasAttr "exporters" c.services.prometheus
    && c.services.prometheus.exporters.${name}.enable or false;
  hasQuadletContainer =
    c: name:
    hasAttr "virtualisation" c
    && hasAttr "quadlet" c.virtualisation
    && hasAttr "containers" c.virtualisation.quadlet
    && hasAttr name c.virtualisation.quadlet.containers;

  # Check if a brew package is installed (for macOS)
  # Brews can be strings or attribute sets with a 'name' field
  hasBrew =
    c: pkgName:
    lib.any (x: (if builtins.isString x then x else x.name) == pkgName) c.homebrew.brews or [ ];

  # Host lists with their configs
  nixosHosts = mapAttrsToList (name: value: {
    inherit name;
    inherit (value) config;
  }) outputs.nixosConfigurations;

  darwinHosts = mapAttrsToList (name: value: {
    inherit name;
    inherit (value) config;
  }) outputs.darwinConfigurations;

  # --- Target Generation Logic ---

  # 1. Node Exporter (Machine metrics)
  # Target: hostname:9100
  nodeTargets =
    let
      linux = concatMap (
        host: if hasExporter host.config "node" then [ "${host.name}:9100" ] else [ ]
      ) nixosHosts;
      mac = concatMap (
        host: if hasBrew host.config "node_exporter" then [ "${host.name}:9100" ] else [ ]
      ) darwinHosts;
      # Static Tailscale targets for machines outside Nix host lists.
      static = [
        "framework.tail030950.ts.net:9100"
      ];
    in
    linux ++ mac ++ static;

  # 2. Blackbox Exporter (The prober itself)
  # Target: hostname:9115
  blackboxExporterTargets =
    if hasExporter config "blackbox" then [ "${config.networking.hostName}:9115" ] else [ ];

  # 3. Libvirt Exporter
  # Target: hostname:9177
  libvirtTargets =
    let
      dynamic = concatMap (
        host: if hasExporter host.config "libvirt" then [ "${host.name}:9177" ] else [ ]
      ) nixosHosts;
      # Static Tailscale targets for machines outside Nix host lists.
      static = [
        "framework.tail030950.ts.net:9177"
      ];
    in
    dynamic ++ static;

  # 4. SmartCTL Exporter
  # Target: hostname:9633
  smartctlTargets = concatMap (
    host: if hasExporter host.config "smartctl" then [ "${host.name}:9633" ] else [ ]
  ) nixosHosts;

  # 4b. Speedtest.net Exporter
  # Target: hostname:9798
  speedtestTargets = concatMap (
    host: if hasExporter host.config "speedtest" then [ "${host.name}:9798" ] else [ ]
  ) nixosHosts;

  # 5. UPS (NUT) Exporter
  # Target: hostname:9199
  # Using services.power.ups.enable check
  nutTargets = concatMap (
    host:
    if hasAttr "ups" host.config.power && host.config.power.ups.enable then
      [ "${host.name}:9199" ]
    else
      [ ]
  ) nixosHosts;

  # 6. EcoFlow Exporter
  # Target: hostname:2112
  ecoflowTargets = concatMap (
    host: if hasExporter host.config "ecoflow" then [ "${host.name}:2112" ] else [ ]
  ) nixosHosts;

  # 7. App Exporters (Radarr, Sonarr, Prowlarr, Postgres)
  appTargets =
    let
      getAppTargets =
        host:
        let
          c = host.config;
        in
        flatten [
          (optionals (hasExporter c "exportarr-radarr") [ "${host.name}:9708" ]) # Radarr
          (optionals (hasExporter c "exportarr-sonarr") [ "${host.name}:9709" ]) # Sonarr
          (optionals (hasExporter c "exportarr-prowlarr") [ "${host.name}:9710" ]) # Prowlarr
          (optionals (hasExporter c "postgres") [ "${host.name}:9187" ]) # Postgres
        ];
    in
    concatMap getAppTargets nixosHosts;

  # 8. Blackbox Ping Targets (Hosts to ping)
  # All NixOS + Darwin hosts
  pingTargets =
    let
      linux = map (h: h.name) nixosHosts;
      mac = map (h: h.name) darwinHosts;
      static = [
        "pikvm"
      ];
    in
    linux ++ mac ++ static;

  # 9. Blackbox HTTP Targets (Apps)
  # Use service-enabled checks to avoid hardcoding hostnames.
  blackboxHttpTargets =
    let
      mkHttpTarget =
        host: serviceName: appName: url:
        optionals (hasService host.config serviceName) [
          {
            targets = [ url ];
            labels = {
              type = "app";
              role = "server";
              app = appName;
            };
          }
        ];
      getTargets =
        host:
        flatten [
          (mkHttpTarget host "radarr" "radarr" "http://${host.name}:7878")
          (mkHttpTarget host "sonarr" "sonarr" "http://${host.name}:8989")
          (mkHttpTarget host "prowlarr" "prowlarr" "http://${host.name}:9696")
          (mkHttpTarget host "immich" "immich" "http://${host.name}:2283/auth/login")
          (mkHttpTarget host "jellyfin" "jellyfin" "http://${host.name}:8096/web/")
          (mkHttpTarget host "jellyseerr" "jellyseerr" "http://${host.name}:5055")
          (mkHttpTarget host "home-assistant" "home-assistant" "http://${host.name}:8123")
          (optionals (hasQuadletContainer host.config "seafile") [
            {
              targets = [ "http://${host.name}:4444" ];
              labels = {
                type = "app";
                role = "server";
                app = "seafile";
              };
            }
          ])
        ];
    in
    concatMap getTargets nixosHosts;

  # 10. Blackbox scrape configs (one per blackbox exporter)
  blackboxScrapes =
    let
      indexed = lib.imap0 (idx: exporter: {
        inherit idx exporter;
      }) blackboxExporterTargets;
      suffixFor = item: "-${toString item.idx}";
    in
    concatMap (
      item:
      let
        inherit (item) exporter;
        suffix = suffixFor item;
      in
      [
        {
          job_name = "blackbox_ping${suffix}";
          metrics_path = "/probe";
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              source_labels = [ "type" ];
              regex = "^$";
              target_label = "type";
              replacement = "app";
              action = "replace";
            }
            {
              source_labels = [ "role" ];
              regex = "^$";
              target_label = "role";
              replacement = "server";
              action = "replace";
            }
            {
              target_label = "__address__";
              replacement = exporter;
            }
          ];
          params.module = [ "icmp" ];
          static_configs = [
            {
              targets = pingTargets;
              labels = {
                type = "node";
                os = "linux"; # Generic, though some are mac
                role = "server";
              };
            }
            {
              targets = [
                "atlantis"
                "ds9"
                "intrepid"
              ];
              labels = {
                type = "node";
                os = "openwrt";
                role = "router";
              };
            }
            {
              targets = [
                "2001:4860:4860::8888"
                "2001:4860:4860::8844"
                "2606:4700:4700::1001"
                "2606:4700:4700::1111"
                "8.8.8.8"
                "8.8.4.4"
                "1.1.1.1"
                "1.0.0.1"
              ];
              labels = {
                role = "canary";
                type = "internet-dns";
              };
            }
          ];
        }
        {
          job_name = "blackbox_http_2xx${suffix}";
          metrics_path = "/probe";
          params.module = [ "http_2xx" ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              source_labels = [
                "app"
                "__param_target"
              ];
              regex = ";https?://([^.]+).*";
              target_label = "app";
              replacement = "$1";
              action = "replace";
            }
            {
              source_labels = [
                "app"
                "__param_target"
              ];
              regex = ";([^.:/]+).*";
              target_label = "app";
              replacement = "$1";
              action = "replace";
            }
            {
              source_labels = [ "type" ];
              regex = "^$";
              target_label = "type";
              replacement = "app";
              action = "replace";
            }
            {
              source_labels = [ "role" ];
              regex = "^$";
              target_label = "role";
              replacement = "server";
              action = "replace";
            }
            {
              target_label = "__address__";
              replacement = exporter;
            }
          ];
          static_configs =
            # Generated per-host based on enabled services.
            blackboxHttpTargets ++ [
              {
                targets = [
                  "http://atlantis"
                  "http://ds9"
                  "http://intrepid"
                ];
                labels = {
                  os = "openwrt";
                  type = "node";
                  role = "router";
                };
              }
            ];
        }
        {
          job_name = "blackbox_https_2xx${suffix}";
          metrics_path = "/probe";
          params.module = [ "https_2xx" ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement = exporter;
            }
          ];
          static_configs = [
            {
              targets = [
                "https://bhaskararaman.com"
                "https://calculon.tech"
                "https://coredump.blog"
                "https://lilaartscentre.com"
                "https://shakthipalace.com"
              ];
              labels.type = "internet-host";
              labels.role = "server";
            }
            {
              targets = [
                "https://www.google.com"
                "https://www.cloudflare.com"
              ];
              labels.type = "internet-host";
              labels.role = "canary";
            }
          ];
        }
        {
          job_name = "blackbox_https_2xx_private${suffix}";
          metrics_path = "/probe";
          params.module = [ "https_2xx" ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement = exporter;
            }
          ];
          file_sd_configs = [
            {
              files = [
                "${vs.victoriametrics}/blackbox_https_2xx_private.json"
              ];
            }
          ];
        }
        {
          job_name = "blackbox_https_2xx_via_warp${suffix}";
          metrics_path = "/probe";
          params.module = [ "https_2xx_via_warp" ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              source_labels = [ "type" ];
              regex = "^$";
              target_label = "type";
              replacement = "app";
              action = "replace";
            }
            {
              source_labels = [ "role" ];
              regex = "^$";
              target_label = "role";
              replacement = "server";
              action = "replace";
            }
            {
              target_label = "__address__";
              replacement = exporter;
            }
            {
              source_labels = [ "__address__" ];
              regex = ".*";
              replacement = "warp";
              target_label = "via";
              action = "replace";
            }
          ];
          static_configs = [
            {
              targets = [
                "https://bhaskararaman.com"
                "https://calculon.tech"
                "https://coredump.blog"
                "https://lilaartscentre.com"
                "https://shakthipalace.com"
              ];
              labels.type = "internet-host";
              labels.role = "server";
            }
            {
              targets = [
                "https://www.google.com"
                "https://www.cloudflare.com"
              ];
              labels.type = "internet-host";
              labels.role = "canary";
            }
          ];
        }
        {
          job_name = "blackbox_https_2xx_via_warp_private${suffix}";
          metrics_path = "/probe";
          params.module = [ "https_2xx_via_warp" ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              source_labels = [
                "app"
                "__param_target"
              ];
              regex = ";https?://([^.]+).*";
              target_label = "app";
              replacement = "$1";
              action = "replace";
            }
            {
              source_labels = [
                "app"
                "__param_target"
              ];
              regex = ";([^.:/]+).*";
              target_label = "app";
              replacement = "$1";
              action = "replace";
            }
            {
              source_labels = [ "type" ];
              regex = "^$";
              target_label = "type";
              replacement = "app";
              action = "replace";
            }
            {
              source_labels = [ "role" ];
              regex = "^$";
              target_label = "role";
              replacement = "server";
              action = "replace";
            }
            {
              target_label = "__address__";
              replacement = exporter;
            }
            {
              source_labels = [ "__address__" ];
              regex = ".*";
              replacement = "warp";
              target_label = "via";
              action = "replace";
            }
          ];
          file_sd_configs = [
            {
              files = [
                "${vs.victoriametrics}/blackbox_https_2xx_private.json"
              ];
            }
          ];
        }
      ]
    ) indexed;

in
{

  services.victoriametrics = {
    enable = true;
    retentionPeriod = "1y";
    extraOptions = [
      "-enableTCP6"
    ];
    prometheusConfig = {
      global.scrape_interval = "10s";

      /**
        Label definitions:

        1. type: node|app|exporter|internet-dns|internet-host
        2. role: server|router|canary|ups
      */

      scrape_configs = [
        {
          job_name = "blackbox_exporter";
          static_configs = [
            {
              targets = blackboxExporterTargets;
              labels.type = "exporter";
            }
          ];
        }
      ]
      ++ blackboxScrapes
      ++ [
        {
          job_name = "network";
          static_configs = [
            {
              targets = [
                "atlantis:9100"
                "ds9:9100"
                "intrepid:9100"
              ];
              labels = {
                os = "openwrt";
                type = "exporter";
                role = "router";
              };
            }
          ];
        }
        {
          job_name = "machines";
          static_configs = [
            {
              targets = nodeTargets;
              labels = {
                type = "exporter";
                role = "server";
              };
            }
          ];
        }
        {
          job_name = "apps";
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              regex = ".*:9708$";
              target_label = "app";
              replacement = "radarr";
              action = "replace";
            }
            {
              source_labels = [ "__address__" ];
              regex = ".*:9709$";
              target_label = "app";
              replacement = "sonarr";
              action = "replace";
            }
            {
              source_labels = [ "__address__" ];
              regex = ".*:9710$";
              target_label = "app";
              replacement = "prowlarr";
              action = "replace";
            }
            {
              source_labels = [ "__address__" ];
              regex = ".*:8096$";
              target_label = "app";
              replacement = "jellyfin";
              action = "replace";
            }
            {
              source_labels = [ "__address__" ];
              regex = ".*:8081$";
              target_label = "app";
              replacement = "immich";
              action = "replace";
            }
            {
              source_labels = [ "__address__" ];
              regex = ".*:8082$";
              target_label = "app";
              replacement = "immich";
              action = "replace";
            }
          ];
          static_configs = [
            {
              targets = appTargets;
              labels.type = "exporter";
              labels.role = "server";
            }
            {
              targets = smartctlTargets;
              labels.type = "exporter";
              labels.role = "disks";
            }
            {
              targets = nutTargets;
              labels.type = "exporter";
              labels.role = "ups";
            }
          ];
        }
        {
          job_name = "nut";
          metrics_path = "/ups_metrics";
          static_configs = [
            {
              targets = nutTargets;
              labels.type = "exporter";
              labels.role = "ups";
            }
          ];
        }
        {
          job_name = "speedtest";
          static_configs = [
            {
              targets = speedtestTargets;
              labels.type = "exporter";
              labels.role = "internet";
            }
          ];
        }
        {
          job_name = "ecoflow";
          static_configs = [
            {
              targets = ecoflowTargets;
              labels.type = "exporter";
              labels.role = "ups";
            }
          ];
        }
        {
          job_name = "libvirt";
          static_configs = [
            {
              targets = libvirtTargets;
              labels.type = "exporter";
              labels.role = "hypervisor";
            }
          ];
        }
        {
          job_name = "home_assistant_6a";
          metrics_path = "/api/prometheus";
          scheme = "https";
          authorization = {
            type = "Bearer";
            credentials_file = "${vs.home-assistant-6a-vm}/access_token";
          };
          static_configs = [
            {
              targets = [ "6a.kedi.dev" ];
              labels.type = "app";
              labels.app = "home-assistant";
            }
          ];
        }
        {
          job_name = "home_assistant_t1";
          metrics_path = "/api/prometheus";
          scheme = "https";
          authorization = {
            type = "Bearer";
            credentials_file = "${vs.home-assistant-t1-vm}/access_token";
          };
          static_configs = [
            {
              targets = [ "t1.kedi.dev" ];
              labels.type = "app";
              labels.app = "home-assistant";
            }
          ];
        }
      ];
    };
  };

  systemd.services.victoriametrics.serviceConfig.ReadOnlyPaths = lib.concatStringsSep " " [
    "${vs.victoriametrics}/blackbox_https_2xx_private.json"
    "${vs.home-assistant-6a-vm}/access_token"
    "${vs.home-assistant-t1-vm}/access_token"
  ];
  systemd.services.victoriametrics = {
    after = [
      "sops-install-secrets.service"
      "home-assistant-6a-vm-secrets.service"
      "home-assistant-t1-vm-secrets.service"
    ];
    requires = [
      "sops-install-secrets.service"
      "home-assistant-6a-vm-secrets.service"
      "home-assistant-t1-vm-secrets.service"
    ];
  };

  users.groups.victoriametrics = lib.mkDefault { };
  users.users.victoriametrics = lib.mkDefault {
    isSystemUser = true;
    group = "victoriametrics";
    extraGroups = [ "hass" ];
  };

  vault-secrets = {
    secrets = {
      victoriametrics = {
        services = [ "victoriametrics" ];
        user = "victoriametrics";
        group = "victoriametrics";
      };

      home-assistant-6a-vm = {
        services = [ "victoriametrics" ];
        user = "victoriametrics";
        group = "victoriametrics";
      };
      home-assistant-t1-vm = {
        services = [ "victoriametrics" ];
        user = "victoriametrics";
        group = "victoriametrics";
      };
    };
  };

}
