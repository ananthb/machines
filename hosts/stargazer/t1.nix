(import ../../services/hass.nix {
  name = "T1";
  secretsPrefix = "home-assistant/t1";
  externalUrl = "https://t1.kedi.dev";
  internalUrl = "http://stargazer.local:8123";
  extraPackages =
    python3Packages: with python3Packages; [
      pyipp
      pywizlight
    ];
})
