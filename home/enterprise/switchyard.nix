{
  config,
  inputs,
  pkgs,
  ...
}: let
  switchyard = inputs.switchyard.packages.${pkgs.stdenv.hostPlatform.system}.default;
  switchyardConfigPath = "${config.xdg.configHome}/switchyard/config.toml";
  chromeWorkDesktopId = "chrome-triton.desktop";
in {
  home = {
    packages = [
      switchyard
    ];

    file."${config.xdg.dataHome}/icons/chrome-triton.png".source = ./assets/chrome-triton.png;
  };

  xdg.desktopEntries.chrome-triton = {
    name = "Chrome (triton.one)";
    exec = "${pkgs.google-chrome}/bin/google-chrome-stable --profile-directory=\"Profile 2\" --class=WorkProfile -- %u";
    terminal = false;
    icon = "${config.xdg.dataHome}/icons/chrome-triton.png";
    type = "Application";
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = ["x-scheme-handler/org-protocol"];
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = ["io.github.alyraffauf.Switchyard.desktop"];
      "x-scheme-handler/https" = ["io.github.alyraffauf.Switchyard.desktop"];
    };
  };

  home.file."${switchyardConfigPath}".text = ''
    prompt_on_click = true
    favorite_browser = ""
    check_default_browser = false

    [[rules]]
    name = 'Triton'
    browser = '${chromeWorkDesktopId}'
    logic = 'any'

    [[rules.conditions]]
    type = 'domain'
    pattern = 'triton.one'

    [[rules.conditions]]
    type = 'glob'
    pattern = '*.triton.one'

    [[rules.conditions]]
    type = 'domain'
    pattern = 'gitbook.com'

    [[rules.conditions]]
    type = 'glob'
    pattern = '*.gitbook.com'

    [[rules.conditions]]
    type = 'domain'
    pattern = 'pagerduty.com'

    [[rules.conditions]]
    type = 'glob'
    pattern = '*.pagerduty.com'

    [[rules.conditions]]
    type = 'domain'
    pattern = 'rpcpool.com'

    [[rules.conditions]]
    type = 'glob'
    pattern = '*.rpcpool.com'

    [[rules.conditions]]
    type = 'domain'
    pattern = 'rpcpool.systems'

    [[rules.conditions]]
    type = 'glob'
    pattern = '*.rpcpool.systems'

    [[rules.conditions]]
    type = 'domain'
    pattern = 'monday.com'

    [[rules.conditions]]
    type = 'glob'
    pattern = '*.monday.com'

    [[rules.conditions]]
    type = 'domain'
    pattern = 'linear.app'

    [[rules.conditions]]
    type = 'glob'
    pattern = '*.linear.app'
  '';
}
