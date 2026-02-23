{ ... }:
{
  imports = [
    ../dev.nix
    ./programs.nix
    ./services.nix
    ./switchyard.nix
  ];

  dconf = {
    enable = true;
    settings = {
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-ac-timeout = 0;
      };
    };
  };

  fonts = {
    fontconfig.enable = true;
  };
}
