{
  pkgs,
  lib,
  ...
}:
{
  # lm_sensors for temperature monitoring
  environment.systemPackages = [
    pkgs.lm_sensors
  ];

  # Clone and run s1panel directly (simpler than packaging)
  systemd.services.s1panel = {
    description = "AceMagic S1 Panel";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    path = with pkgs; [
      nodejs_20
      git
      lm_sensors
      bash
      coreutils
      gnumake
      gcc
      python3
      pkg-config
      libusb1
      udev
      cairo
      pango
      libjpeg
      giflib
      librsvg
      pixman
    ];

    environment = {
      HOME = "/var/lib/s1panel";
      npm_config_nodedir = "${pkgs.nodejs_20}";
      C_INCLUDE_PATH = "${pkgs.udev.dev}/include:${pkgs.libusb1.dev}/include";
      LIBRARY_PATH = "${pkgs.udev.out}/lib:${pkgs.libusb1.out}/lib";
      LD_LIBRARY_PATH = lib.makeLibraryPath [
        pkgs.util-linux
        pkgs.udev
        pkgs.libusb1
        pkgs.cairo
        pkgs.pango
        pkgs.libjpeg
        pkgs.giflib
        pkgs.librsvg
        pkgs.pixman
        pkgs.glib
        pkgs.fontconfig
        pkgs.freetype
        pkgs.libpng
        pkgs.harfbuzz
      ];
    };

    preStart = ''
      if [ ! -f /var/lib/s1panel/s1panel/main.js ]; then
        rm -rf /var/lib/s1panel/*
        ${pkgs.git}/bin/git clone https://github.com/tjaworski/AceMagic-S1-LED-TFT-Linux.git /var/lib/s1panel/repo
        mv /var/lib/s1panel/repo/* /var/lib/s1panel/
        rm -rf /var/lib/s1panel/repo
        cd /var/lib/s1panel/s1panel
        export PKG_CONFIG_PATH="${
          lib.makeSearchPath "lib/pkgconfig" [
            pkgs.libusb1.dev
            pkgs.udev.dev
            pkgs.cairo.dev
            pkgs.pango.dev
            pkgs.pixman
            pkgs.glib.dev
            pkgs.freetype.dev
            pkgs.fontconfig.dev
            pkgs.libpng.dev
            pkgs.harfbuzz.dev
          ]
        }"
        ${pkgs.nodejs_20}/bin/npm install --legacy-peer-deps
        cd gui
        ${pkgs.nodejs_20}/bin/npm install --legacy-peer-deps
        ${pkgs.nodejs_20}/bin/npm run build || true
      fi
    '';

    script = ''
      cd /var/lib/s1panel/s1panel
      exec ${pkgs.nodejs_20}/bin/node main.js
    '';

    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = 5;
      StateDirectory = "s1panel";
    };
  };

  # udev rules for non-root access to USB devices
  services.udev.extraRules = ''
    # Holtek TFT LCD Display
    SUBSYSTEM=="usb", ATTR{idVendor}=="04d9", ATTR{idProduct}=="fd01", MODE="0666"
    KERNEL=="hidraw*", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="fd01", MODE="0666"
    # CH340 USB Serial for RGB LEDs
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666", GROUP="dialout"
  '';

  users.users.ananth.extraGroups = [ "dialout" ];
}
