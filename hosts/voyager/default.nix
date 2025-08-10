{
  config,
  lib,
  pkgs,
  hostname,
  username,
  tsnsrv,
  ...
}:
{
  imports = [
    tsnsrv.nixosModules.default
    ./hardware-configuration.nix
    ./hass.nix
    ./homepage.nix
    ./monitoring.nix
  ];

  sops.secrets."email/smtp/username".owner = config.users.users.grafana.name;
  sops.secrets."email/smtp/password".owner = config.users.users.grafana.name;
  sops.secrets."email/smtp/host".owner = config.users.users.grafana.name;

  systemd.enableEmergencyMode = false;
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
  '';

  networking.hostName = hostname;
  networking.firewall.enable = true;
  networking.firewall.allowPing = true;

  # System packages
  environment.systemPackages = with pkgs; [
    pam_rssh
    e2fsprogs
    tsnsrv
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

  security = {
    pam.rssh.enable = true;
    pam.rssh.settings = {
      auth_key_file = "/etc/ssh/authorized_keys.d/ananth";
      loglevel = "debug";
    };
    pam.services.sudo.rssh = true;
    pam.services.sshd.rssh = true;
  };

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
