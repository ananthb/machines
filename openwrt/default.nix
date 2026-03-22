{
  openwrt-imagebuilder,
  pkgs,
}: let
  profiles = openwrt-imagebuilder.lib.profiles {inherit pkgs;};

  # Common packages shared across all routers
  commonPackages = [
    "luci"
    "luci-ssl"
    "luci-app-attendedsysupgrade"
    "luci-app-firewall"
    "luci-app-package-manager"
    "tailscale"
  ];

  # Packages for routers using nginx (instead of uhttpd) for LuCI
  nginxPackages = [
    "luci-nginx"
  ];

  # Prometheus monitoring stack
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

  # DAWN 802.11k/r/v roaming
  dawnPackages = [
    "dawn"
    "luci-app-dawn"
    "wpad-wolfssl"
    "-wpad-basic-mbedtls"
  ];

  # SQM (Smart Queue Management) for bufferbloat
  sqmPackages = [
    "luci-app-sqm"
    "sqm-scripts"
  ];

  mkImage = config:
    openwrt-imagebuilder.lib.build config;
in {
  # intrepid: GL-MT3000, AP mode mesh node
  intrepid = mkImage (profiles.identifyProfile "glinet_gl-mt3000"
    // {
      release = "25.12.1";
      packages =
        commonPackages
        ++ nginxPackages
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
    });

  # ds9: GL-MT3000, travel router
  ds9 = mkImage (profiles.identifyProfile "glinet_gl-mt3000"
    // {
      release = "25.12.1";
      packages =
        commonPackages
        ++ sqmPackages
        ++ [
          "adblock-fast"
          "luci-app-adblock-fast"
          "https-dns-proxy"
          "luci-app-https-dns-proxy"
          "curl"
        ];
    });

  # atlantis: GL-MT6000, main home router
  atlantis = mkImage (profiles.identifyProfile "glinet_gl-mt6000"
    // {
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
    });
}
