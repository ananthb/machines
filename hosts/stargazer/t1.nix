(import ../../services/hass.nix {
  name = "T1";
  secretsPrefix = "homes/t1";
  externalUrl = "https://t1.kedi.dev";
  internalUrl = "http://stargazer.local:8123";
})
