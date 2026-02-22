{ config, lib, ... }:
let
  inherit (lib) mkOption types;

  stripServiceSuffix =
    name: if lib.hasSuffix ".service" name then lib.removeSuffix ".service" name else name;

  normalize = names: lib.unique (map stripServiceSuffix names);

  cfg = config.my-services;

  manualUnits = normalize (cfg.restartUnits or [ ]);
  autoUnits = normalize (
    lib.attrNames (lib.filterAttrs (_name: enabled: enabled) (cfg.kediTargets or { }))
  );
  excludedUnits = normalize (cfg.restartUnitsExclude or [ ]);

  finalUnits = lib.subtractLists excludedUnits (manualUnits ++ autoUnits);

  unitNames = map (name: "${name}.service") finalUnits;
in
{
  options.my-services = {
    kediTargets = mkOption {
      type = types.attrsOf types.bool;
      default = { };
      description = "Attrset of systemd service names to include in kedi.target when set to true.";
    };

    restartUnits = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra systemd service units to include in kedi.target (names without .service).";
    };

    restartUnitsExclude = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Systemd service units to exclude from kedi.target (names without .service).";
    };
  };

  config = {
    systemd.targets.kedi = {
      description = "Kedi services";
      wants = unitNames;
    };
  };
}
