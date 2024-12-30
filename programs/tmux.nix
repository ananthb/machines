{ pkgs, ... }:
{
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
}
