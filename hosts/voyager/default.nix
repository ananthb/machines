{
  config,
  ...
}:
{
  imports = [
    ../linux

    ./actual.nix
    ./davis.nix
    ./hardware-configuration.nix
    ./hass.nix
    ./monitoring.nix
    ./radicale.nix
  ];

  # System packages
  environment.systemPackages = [ ];

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  power.ups = {
    enable = true;
    mode = "netclient";

    users = {
      "nutmon" = {
        passwordFile = config.sops.secrets."nut/users/nutmon".path;
        upsmon = "primary";
      };
    };

    upsmon.monitor."apc1@endeavour" = {
      powerValue = 1;
      user = "nutmon";
    };
  };

  # Jellyseerr
  services = {
    jellyseerr.enable = true;

    tsnsrv.services.watch = {
      funnel = true;
      urlParts.port = 5055;
    };

    postgresql = {
      enable = true;
      ensureDatabases = [ "jellyseerr" ];
      ensureUsers = [
        {
          name = "jellyseerr";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };
  };

  systemd.services = {
    tsnsrv-watch.wants = [ "jellyseerr.service" ];
    tsnsrv-watch.after = [ "jellyseerr.service" ];

    jellyseerr.environment = {
      DB_TYPE = "postgres";
      DB_SOCKET_PATH = "/var/run/postgresql";
      DB_USER = "jellyseerr";
      DB_NAME = "jellyseerr";
    };
  };

  # secrets
  sops.secrets."email/smtp/username".owner = config.users.users.grafana.name;
  sops.secrets."email/smtp/password".owner = config.users.users.grafana.name;
  sops.secrets."email/smtp/host".owner = config.users.users.grafana.name;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
