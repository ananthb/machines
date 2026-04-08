{...}: {
  imports = [../../services/hass.nix];

  my-services.hass = {
    enable = true;
    name = "T1";
    secretsPrefix = "home-assistant/t1";
    externalUrl = "https://t1.kedi.dev";
    internalUrl = "http://stargazer.local:8123";
  };

  services.home-assistant.extraPackages = ps: [ps.pyipp ps.pywizlight];
}
