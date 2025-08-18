{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./hass.nix
    ./homepage.nix
    ./monitoring.nix
  ];

  # service to control the fan
  systemd.services.fan-control = {
    description = "Control the fan depending on the temperature";
    script = ''
      /run/current-system/sw/bin/gpio init 14 out
      temperature=$(/run/current-system/sw/bin/vcgencmd measure_temp | grep -oE '[0-9]+([.][0-9]+)?')
      threshold=65
      if /run/current-system/sw/bin/awk -v temp="$temperature" -v threshold="$threshold" 'BEGIN { exit !(temp > threshold) }'; then
        /run/current-system/sw/bin/gpio write 14 hi
      else
        /run/current-system/sw/bin/gpio write 14 lo
      fi
      /run/current-system/sw/bin/gpio close 14 out
    '';
  };

  systemd.timers.fan-control-timer = {
    description = "Run control fan script regularly";
    timerConfig = {
      OnCalendar = "*-*-* *:0/1:00"; # Run every 10 minutes
      Persistent = true;
      Unit = "fan-control.service";
    };
    wantedBy = [ "timers.target" ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    haskellPackages.gpio
    libraspberrypi
  ];

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

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
