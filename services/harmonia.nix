{
  config,
  ...
}:
let
  nixCache = import ../lib/nix-cache.nix;
in
{
  services.harmonia = {
    enable = true;
    signKeyPaths = [ config.sops.secrets."harmonia/signing-key".path ];
    settings.bind = "[::]:${toString nixCache.cachePort}";
  };

  sops.secrets."harmonia/signing-key" = { };
}
