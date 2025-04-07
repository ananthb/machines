{
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

    selection = { save_to_clipboard = true; };

    window = { dynamic_title = true; };

    general = { live_config_reload = true; };

    terminal = {
      shell = {
        program = "fish";
        args =
          [ "-l" "-i" "-c" "tmux attach -t main || tmux new-session -t main" ];
      };
    };
  };
}
