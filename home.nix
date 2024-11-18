{ pkgs, ... }:
{
  home.username = "ananth";
  home.homeDirectory = "/home/ananth";
  home.sessionVariables.EDITOR = "nvim";

  home.packages = [
    pkgs.atool
    pkgs.httpie
    pkgs.firefox
    pkgs.tree
    pkgs.alacritty
    pkgs.fish
    pkgs.git
    pkgs.curl
    pkgs.httpie
    pkgs.htop
    pkgs.neovide
    pkgs.wireshark
    pkgs.hack-font
    pkgs.moolticute
    pkgs.delta
    pkgs.tokei
    pkgs.fzf
    pkgs.git-credential-manager
  ];

  fonts = {
    fontconfig.enable = true;
  };

  programs.fish.enable = true;
  programs.home-manager.enable = true;
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        bold = {
          family = "Hack";
          style = "Bold";
        };

        bold_italic = {
          family = "Hack";
          style = "Bold Italic";
        };

        italic = {
          family = "Hack";
          style = "Italic";
        };

        normal = {
          family = "Hack";
          style = "Regular";
        };
      };

      selection = {
        save_to_clipboard = true;
      };

      window = {
        dynamic_title = true;
      };

      general = {
        live_config_reload = true;
      };

      terminal = {
        shell = {
          program = "fish";
          args = [
            "-l"
            "-i"
            "-c"
            "tmux attach -t main || tmux new-session -t main"
          ];
        };
      };
    };
  };

  programs.git = {
    enable = true;
    userName = "Ananth Bhaskararaman";
    userEmail = "antsub@gmail.com";

    aliases = {
      a = "add";
      b = "branch";
      c = "commit";
      p = "push";
      r = "reset";
      s = "status -sb";
      sw = "switch";
      co = "checkout";
      cp = "cherry-pick";
    };

    extraConfig = {
      core.pager = "delta";
      user.useConfigOnly = "true";
      init.defaultBranch = "main";

      credential = {
        credentialStore = "cache";
        helper = "manager";
        "https://github.com".username = "ananthb";
      };

      color = {
        ui = "true";
        diff = "auto";
        status = "auto";
        branch = "auto";
      };

      advice = {
        pushNonFastForward = "false";
        statusHints = "false";
        commitBeforeMerge = "false";
        resolveConflict = "false";
        implicitIdentity = "false";
        detachedHead = "false";
      };

      push.autoSetupRemote = true;
      rerere.enabled = "true";
      column.ui = "auto";
      branch.sort = "-committerdate";
      merge.conflictStyle = "zdiff3";
      diff.algorithm = "histogram";
      transfer.fsckObjects = "true";
      fetch.fsckObjects = "true";

      receive.fsckObjects = "true";
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
      nvim-treesitter.withAllGrammars
      plenary-nvim
      gruvbox-material
      mini-nvim
    ];
  };

  programs.tmux = {
    enable = true;
    historyLimit = 100000;
    shortcut = "a";
    keyMode = "vi";
    mouse = true;
    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-vim 'session'
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-boot 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];
    extraConfig = '''';
  };

  home.stateVersion = "24.05";
}
