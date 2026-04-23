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

      # Workspace settings
      "org/gnome/mutter" = {
        dynamic-workspaces = false;
        workspaces-only-on-primary = false;
        edge-tiling = true;
      };
      "org/gnome/desktop/wm/preferences" = {
        num-workspaces = 4;
      };

      # Workspace keybindings
      "org/gnome/desktop/wm/keybindings" = {
        switch-to-workspace-1 = ["<Super>1"];
        switch-to-workspace-2 = ["<Super>2"];
        switch-to-workspace-3 = ["<Super>3"];
        switch-to-workspace-4 = ["<Super>4"];
        move-to-workspace-1 = ["<Super><Shift>1"];
        move-to-workspace-2 = ["<Super><Shift>2"];
        move-to-workspace-3 = ["<Super><Shift>3"];
        move-to-workspace-4 = ["<Super><Shift>4"];
      };

      # Forge tiling defaults
      "org/gnome/shell/extensions/forge" = {
        window-gap-size = 4;
        window-gap-size-increment = 1;
        window-gap-hidden-on-single = true;
      };
    };
  };

  fonts = {
    fontconfig.enable = true;
  };
}
