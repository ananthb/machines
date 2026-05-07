{...}: {
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

      # PaperWM expects dynamic workspaces (it manages the strip itself); leave
      # mutter at its defaults rather than forcing a static 4-workspace setup.
      "org/gnome/mutter" = {
        dynamic-workspaces = true;
        workspaces-only-on-primary = false;
        edge-tiling = true;
      };
    };
  };

  fonts = {
    fontconfig.enable = true;
  };
}
