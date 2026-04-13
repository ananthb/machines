{pkgs, ...}: {
  programs = {
    atuin = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        style = "compact";
        inline_height = 20;
        show_preview = true;
        enter_accept = true;
      };
    };

    bat = {
      enable = true;
      config.theme = "base16-256";
    };

    eza = {
      enable = true;
      enableFishIntegration = true;
      git = true;
      icons = "auto";
    };

    fd = {
      enable = true;
    };

    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting ""
      '';
      shellAbbrs = {
        g = "git";
        ga = "git add";
        gc = "git commit";
        gca = "git commit --amend";
        gco = "git checkout";
        gd = "git diff";
        gds = "git diff --staged";
        gl = "git log --oneline";
        gp = "git push";
        gpf = "git push --force-with-lease";
        gr = "git rebase";
        gs = "git status -sb";
        gsw = "git switch";

        dc = "docker compose";
        dcu = "docker compose up -d";
        dcd = "docker compose down";
        dcl = "docker compose logs -f";

        k = "kubectl";
        tf = "terraform";

        nr = "nix run";
        ns = "nix shell";
        nb = "nix build";
        nf = "nix flake";
        nd = "nix develop";

        lg = "lazygit";
        v = "nvim";
        cat = "bat";
      };
    };

    starship = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        add_newline = false;
        format = "$directory$git_branch$git_status$nix_shell$kubernetes$cmd_duration$line_break$character";
        directory = {
          truncation_length = 3;
          truncate_to_repo = true;
        };
        git_branch.format = "[$branch]($style) ";
        git_status.format = "([\\[$all_status$ahead_behind\\]]($style) )";
        nix_shell = {
          format = "[$symbol$state]($style) ";
          symbol = "nix ";
        };
        kubernetes = {
          disabled = false;
          format = "[$context(/$namespace)]($style) ";
        };
        cmd_duration = {
          min_time = 2000;
          format = "[$duration]($style) ";
        };
        character = {
          success_symbol = "[>](bold green)";
          error_symbol = "[>](bold red)";
        };
      };
    };

    tmux = {
      enable = true;
      historyLimit = 100000;
      shortcut = "a";
      keyMode = "vi";
      mouse = true;
      terminal = "tmux-256color";
      escapeTime = 0;
      plugins = with pkgs.tmuxPlugins; [
        better-mouse-mode
        vim-tmux-navigator
        yank
        {
          plugin = resurrect;
          extraConfig = ''
            set -g @resurrect-strategy-vim 'session'
            set -g @resurrect-strategy-nvim 'session'
            set -g @resurrect-capture-pane-contents 'on'
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-boot 'on'
            set -g @continuum-save-interval '10'
          '';
        }
        {
          plugin = tmux-thumbs;
          extraConfig = ''
            set -g @thumbs-key F
            set -g @thumbs-command 'echo -n {} | pbcopy'
          '';
        }
        {
          plugin = catppuccin;
          extraConfig = ''
            set -g @catppuccin_flavor 'mocha'
            set -g @catppuccin_window_status_style 'rounded'
          '';
        }
      ];
      extraConfig = ''
        # True color support
        set -ag terminal-overrides ",xterm-256color:RGB"

        # Vim-style pane resizing
        bind -r H resize-pane -L 5
        bind -r J resize-pane -D 5
        bind -r K resize-pane -U 5
        bind -r L resize-pane -R 5

        # Split panes with | and -
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"

        # New window in current path
        bind c new-window -c "#{pane_current_path}"

        # Status bar
        set -g status-right "#{?client_prefix,#[reverse] PREFIX #[noreverse] ,}%H:%M"
        set -g status-left "[#S] "
        set -g status-left-length 30
      '';
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
