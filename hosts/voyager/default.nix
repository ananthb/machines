{
  config,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./hass.nix
    ./homepage.nix
    ./monitoring.nix
  ];

  # System packages
  environment.systemPackages = [ ];

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  services.open-webui.enable = true;
  services.open-webui.port = 8090;
  services.open-webui.environmentFile = config.sops.templates."open-webui/env".path;

  sops.templates."open-webui/env" = {
    mode = 0444;
    content = ''
      ENABLE_PERSISTENT_CONFIG="False"
      OLLAMA_API_BASE_URL="http://enterprise:11434"
      ENABLE_SIGNUP="True"
      ENABLE_OAUTH_SIGNUP="True"
      ENABLE_OAUTH_PERSISTENT_CONFIG="False"
      GOOGLE_CLIENT_ID="${config.sops.placeholder."keys/oauth_clients/open-webui/client_id"}"
      GOOGLE_CLIENT_SECRET="${config.sops.placeholder."keys/oauth_clients/open-webui/client_secret"}"
      GOOGLE_REDIRECT_URI="https://ai.${config.sops.placeholder."keys/tailscale_api/tailnet"}/oauth/google/callback"
    '';
  };
  
  services.tsnsrv.services.ai = {
    # funnel = true;
    urlParts.port = 8090;
  };

  # secrets
  sops.secrets."email/smtp/username".owner = config.users.users.grafana.name;
  sops.secrets."email/smtp/password".owner = config.users.users.grafana.name;
  sops.secrets."email/smtp/host".owner = config.users.users.grafana.name;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
