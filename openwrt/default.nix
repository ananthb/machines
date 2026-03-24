{
  openwrt-imagebuilder,
  pkgs,
}: let
  profiles = openwrt-imagebuilder.lib.profiles {inherit pkgs;};

  commonPackages = [
    "luci"
    "luci-ssl"
    "luci-app-attendedsysupgrade"
    "luci-app-firewall"
    "luci-app-package-manager"
    "tailscale"
  ];

  nginxPackages = [
    "luci-nginx"
  ];

  prometheusPackages = [
    "prometheus-node-exporter-lua"
    "prometheus-node-exporter-lua-dawn"
    "prometheus-node-exporter-lua-hostapd_stations"
    "prometheus-node-exporter-lua-hwmon"
    "prometheus-node-exporter-lua-nat_traffic"
    "prometheus-node-exporter-lua-netstat"
    "prometheus-node-exporter-lua-openwrt"
    "prometheus-node-exporter-lua-thermal"
    "prometheus-node-exporter-lua-wifi_stations"
    "prometheus-node-exporter-lua-wifi"
  ];

  dawnPackages = [
    "dawn"
    "luci-app-dawn"
    "wpad-wolfssl"
    "-wpad-basic-mbedtls"
  ];

  sqmPackages = [
    "luci-app-sqm"
    "sqm-scripts"
  ];

  routers = {
    intrepid = {
      profile = "glinet_gl-mt3000";
      release = "25.12.1";
      packages =
        commonPackages
        ++ prometheusPackages
        ++ dawnPackages
        ++ [
          "bind-dig"
          "bind-host"
          "ip-full"
          "-ip-tiny"
          "tcpdump"
          "shadow-useradd"
        ];
      # Config files stored in Vault, not baked in at eval time
      extraFiles = [];
    };

    ds9 = {
      profile = "glinet_gl-mt3000";
      release = "25.12.1";
      packages =
        commonPackages
        ++ sqmPackages
        ++ [
          "adblock-fast"
          "luci-app-adblock-fast"
          "https-dns-proxy"
          "luci-app-https-dns-proxy"
          "travelmate"
          "luci-app-travelmate"
          "wifischedule"
          "luci-app-wifischedule"
          "watchcat"
          "luci-app-watchcat"
          "curl"
        ];
      extraFiles = [];
    };

    atlantis = {
      profile = "glinet_gl-mt6000";
      release = "25.12.0";
      packages =
        commonPackages
        ++ nginxPackages
        ++ prometheusPackages
        ++ dawnPackages
        ++ sqmPackages
        ++ [
          "adguardhome"
          "conntrack"
          "curl"
          "e2fsprogs"
          "ethtool-lua"
          "htop"
          "httping"
          "ip-bridge"
          "mdns-repeater"
          "shadow-useradd"
          "tcpdump"
          "prometheus-node-exporter-lua-ethtool"
        ];
      extraFiles = [];
    };
  };

  # Build an image without config (packages only).
  # Used by nix build .#openwrt-{name}
  mkImage = _name: cfg:
    openwrt-imagebuilder.lib.build (profiles.identifyProfile cfg.profile
      // {
        inherit (cfg) release packages;
      });

  # Build an image with config files baked in.
  # filesDir is a path to a directory with the filesystem overlay (etc/config/*, etc.)
  mkImageWithFiles = _name: cfg: filesDir:
    openwrt-imagebuilder.lib.build (profiles.identifyProfile cfg.profile
      // {
        inherit (cfg) release packages;
        files = filesDir;
      });
in {
  # Package-only images (pure, no secrets needed)
  images = builtins.mapAttrs mkImage routers;

  # Function to build images with config baked in (called by deploy app)
  buildWithFiles = builtins.mapAttrs mkImageWithFiles routers;

  # Export router metadata for use by apps
  inherit routers;
}
