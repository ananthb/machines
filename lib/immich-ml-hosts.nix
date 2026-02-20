{
  lib,
  immichMlImage,
  nixosConfigurations,
  ...
}:
let
  inherit (lib) attrNames filterAttrs any;
in
attrNames (
  filterAttrs (
    _: cfg:
    let
      containers = cfg.config.virtualisation.quadlet.containers or { };
    in
    any (c: (c.containerConfig.image or "") == immichMlImage) (builtins.attrValues containers)
  ) nixosConfigurations
)
