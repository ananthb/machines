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

  xdg.desktopEntries = {
    chrome-triton = {
      name = "Chrome — Work (triton.one)";
      genericName = "Web Browser";
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

    # Override the package-shipped google-chrome.desktop so the chooser
    # shows it as the personal profile (and pins it to "Default" instead
    # of whichever profile Chrome happened to open last).
    google-chrome = {
      name = "Chrome — Personal";
      genericName = "Web Browser";
      exec = "${pkgs.google-chrome}/bin/google-chrome-stable --profile-directory=\"Default\" --class=PersonalProfile %U";
      terminal = false;
      icon = "google-chrome";
      type = "Application";
      startupNotify = true;
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeType = [
        "application/pdf"
        "application/rdf+xml"
        "application/rss+xml"
        "application/xhtml+xml"
        "application/xhtml_xml"
        "application/xml"
        "image/gif"
        "image/jpeg"
        "image/png"
        "image/webp"
        "text/html"
        "text/xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/google-chrome"
      ];
      actions = {
        new-window = {
          name = "New Window";
          exec = "${pkgs.google-chrome}/bin/google-chrome-stable --profile-directory=\"Default\"";
        };
        new-private-window = {
          name = "New Incognito Window";
          exec = "${pkgs.google-chrome}/bin/google-chrome-stable --profile-directory=\"Default\" --incognito";
        };
      };
    };
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

    # rpcpool / triton infrastructure
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
    pattern = 'rpcpool.wg'

    [[rules.conditions]]
    type = 'glob'
    pattern = '*.rpcpool.wg'

    [[rules.conditions]]
    type = 'domain'
    pattern = 'triton.one'

    [[rules.conditions]]
    type = 'glob'
    pattern = '*.triton.one'

    [[rules.conditions]]
    type = 'domain'
    pattern = 'llama-pomano.ts.net'

    [[rules.conditions]]
    type = 'glob'
    pattern = '*.llama-pomano.ts.net'

    # GitHub: only the rpcpool org, not the rest of github.com.
    # Matches github.com/rpcpool and github.com/rpcpool/* but not github.com/rpcpool-foo.
    [[rules.conditions]]
    type = 'regex'
    pattern = '^https?://github\.com/rpcpool($|/)'

    # work SaaS
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

    [[rules.conditions]]
    type = 'domain'
    pattern = 'slack.com'

    [[rules.conditions]]
    type = 'glob'
    pattern = '*.slack.com'
  '';
}
