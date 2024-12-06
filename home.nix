{
  pkgs,
  inputs,
  ...
}:
{

  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];

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
    pkgs.gnomeExtensions.appindicator
  ];

  dconf.settings = {
   "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "org.gnome.shell.extensions.appindicator"
      ];
    };
  };

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

  programs.nixvim = {
    enable = true;

    colorschemes.oxocarbon.enable = true;

    plugins = {

      lualine.enable = true;

      # Includes all parsers for treesitter
      treesitter = {
        enable = true;
      };

      # Icons 
      web-devicons.enable = true;

      sleuth = {
        enable = true;
      };

      # Autopairs
      nvim-autopairs = {
        enable = true;
      };

      # Trouble
      trouble = {
        enable = true;
      };

      which-key = {
        enable = false;
        registrations = {
          "<leader>fg" = "Find Git files with telescope";
          "<leader>fw" = "Find text with telescope";
          "<leader>ff" = "Find files with telescope";
        };
      };

      # Prettier fancier command window
      noice = {
        enable = true;
      };

      # Good old Telescope
      telescope = {
        enable = true;
        extensions = {
          fzf-native = {
            enable = true;
          };
        };
      };

      # Todo comments
      todo-comments = {
        enable = true;
        settings.colors = {
          error = [
            "DiagnosticError"
            "ErrorMsg"
            "#DC2626"
          ];
          warning = [
            "DiagnosticWarn"
            "WarningMsg"
            "#FBBF24"
          ];
          info = [
            "DiagnosticInfo"
            "#2563EB"
          ];
          hint = [
            "DiagnosticHint"
            "#10B981"
          ];
          default = [
            "Identifier"
            "#7C3AED"
          ];
          test = [
            "Identifier"
            "#FF00FF"
          ];
        };
      };

      # Language server
      lsp = {
        enable = true;
        servers = {
          # Average webdev LSPs
          # ts-ls.enable = true; # TS/JS
          ts_ls.enable = true; # TS/JS
          cssls.enable = true; # CSS
          html.enable = true; # HTML
          pyright.enable = true; # Python
          marksman.enable = true; # Markdown
          nil_ls.enable = true; # Nix
          dockerls.enable = true; # Docker
          bashls.enable = true; # Bash
          clangd.enable = true; # C/C++
          yamlls.enable = true; # YAML
          ltex = {
            enable = true;
            settings = {
              enabled = [
                "html"
                "latex"
                "markdown"
                "text"
                "tex"
                "gitcommit"
              ];
              completionEnabled = true;
              language = "en-US";
            };
          };
          gopls = {
            # Golang
            enable = true;
            autostart = true;
          };

          lua_ls = {
            # Lua
            enable = true;
            settings.telemetry.enable = false;
          };

          # Rust
          rust_analyzer = {
            enable = true;
            installRustc = true;
            installCargo = true;
          };
        };
      };

    };
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
