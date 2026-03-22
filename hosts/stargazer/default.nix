{...}: {
  imports = [
    ../linux.nix
    ./hardware-configuration.nix

    ./t1.nix
    ../../services/mealie.nix
    ../../services/timemachinesrv.nix
    ../../services/monitoring/blackbox.nix
    ../../services/monitoring/probes.nix
  ];

  # Open Samba ports for LAN access (Time Machine)
  services.samba.openFirewall = true;

  # System packages
  environment.systemPackages = [];

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  my-services.cftunnelConfig = [
    {
      tunnelId = "b6a4a4a7-3f48-4b10-a39f-fc2ef1f7b0c7";
      tunnelName = "kedi-ext-1";
      ingress = {
        "t1.kedi.dev" = "http://localhost:8123";
        "mealie.kedi.dev" = "http://localhost:9000";
      };
    }
  ];

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
