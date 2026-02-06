{ pkgs, ... }:
{
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting ""
      '';
    };

    tmux = {
      enable = true;
      historyLimit = 100000;
      shortcut = "a";
      keyMode = "vi";
      mouse = true;
      plugins = with pkgs.tmuxPlugins; [
        better-mouse-mode
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
          plugin = fpp;
        }
        {
          plugin = copycat;
        }
        # TODO: https://github.com/nixos/nixpkgs/issues/487193
        #{
        #  plugin = fingers;
        #}
        {
          plugin = urlview;
        }
      ];
      extraConfig = "";
    };
  };

}
