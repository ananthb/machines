{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nix-openclaw.homeManagerModules.openclaw
    ../dev.nix
  ];

  services.activitywatch.enable = true;

  home.packages = with pkgs; [
    discord
    element-desktop
    firefox
    gcr
    ghostty
    gimp
    google-chrome
    jamesdsp
    jellyfin-media-player
    junction
    rpi-imager
    signal-desktop
    slack
    telegram-desktop
    vlc
    vscode
    wireshark
    wl-clipboard
    zed-editor
  ];

  services = {
    gnome-keyring.enable = true;
  };

  programs = {
    gnome-shell = {
      enable = true;
      extensions = with pkgs.gnomeExtensions; [
        { package = another-window-session-manager; }
        { package = appindicator; }
        { package = gsconnect; }
        { package = night-theme-switcher; }
        { package = system-monitor; }
        { package = tailscale-status; }
        { package = tiling-shell; }
      ];
    };

    git.settings = {
      credential = {
        helper = "!/etc/profiles/per-user/ananth/bin/gh auth git-credential";
        "https://github.com".username = "ananthb";
      };
    };

  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-ac-timeout = 0;
      };
    };
  };

  xdg.desktopEntries.chrome-triton = {
    name = "Chrome (triton.one)";
    exec = "/etc/profiles/per-user/ananth/bin/google-chrome-stable --profile-directory=\"Profile 2\" --class=WorkProfile -- %u";
    terminal = false;
    icon = "google-chrome";
    type = "Application";
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = [ "x-scheme-handler/org-protocol" ];
  };

  fonts = {
    fontconfig.enable = true;
  };

  programs.openclaw = {
    enable = true;
    documents = ./openclaw-documents;
    instances.default = {
      enable = true;
      plugins = [ ];
      config = {
        gateway = {
          mode = "local";
        };
        agents.defaults.model = {
          primary = "openai/gpt-5";
          fallbacks = [ "ollama/llama3.2:3b" ];
        };
        models = {
          mode = "merge";
          providers = {
            ollama = {
              api = "openai-responses";
              auth = "token";
              apiKey = "ollama";
              authHeader = false;
              baseUrl = "http://127.0.0.1:11434/v1";
              models = [
                {
                  id = "llama3.2:3b";
                  name = "Ollama Llama 3.2 3B";
                  contextWindow = 128000;
                }
                {
                  id = "deepseek-r1:1.5b";
                  name = "Ollama DeepSeek R1 1.5B";
                  contextWindow = 128000;
                }
              ];
            };
          };
        };
        channels.telegram = {
          tokenFile = config.sops.secrets."telegram/openclaw/bot_token".path;
          allowFrom = [ 1200030352 ];
          groups."*" = {
            requireMention = true;
          };
        };
      };
    };
  };

  sops.secrets = {
    "telegram/openclaw/bot_token" = { };
    "openclaw/gateway_token" = { };
    "openclaw/openai_api_key" = { };
  };

  sops.templates."openclaw/env".content = ''
    OPENCLAW_GATEWAY_TOKEN=${config.sops.placeholder."openclaw/gateway_token"}
    OPENAI_API_KEY=${config.sops.placeholder."openclaw/openai_api_key"}
  '';

  systemd.user.services.openclaw-gateway.Service = {
    EnvironmentFile = config.sops.templates."openclaw/env".path;
    StandardError = lib.mkForce "journal";
    StandardOutput = lib.mkForce "journal";
  };

  home.file.".openclaw/openclaw.json".force = true;

}
