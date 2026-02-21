{ config, lib, ... }:
let
  inherit (lib) mkOption types;

  stripServiceSuffix =
    name: if lib.hasSuffix ".service" name then lib.removeSuffix ".service" name else name;

  normalize = names: lib.unique (map stripServiceSuffix names);

  cfg = config.my-services;

  vaultUnits =
    let
      secrets = config.vault-secrets.secrets or { };
    in
    lib.concatMap (s: s.services or [ ]) (lib.attrValues secrets);

  quadletUnits = lib.attrNames (config.virtualisation.quadlet.containers or { });

  exporterUnits =
    let
      exporters = config.services.prometheus.exporters or { };
      enabled = lib.filterAttrs (_: v: v ? enable && v.enable) exporters;
    in
    map (name: "prometheus-${name}-exporter") (lib.attrNames enabled);

  tsnsrvUnits =
    let
      services = config.services.tsnsrv.services or { };
    in
    map (name: "tsnsrv-${name}") (lib.attrNames services);

  immichUnits =
    if config.services.immich.enable or false then
      [
        "immich-server"
        "immich-microservices"
      ]
    else
      [ ];

  sambaUnits = if config.services.samba.enable or false then [ "samba-smbd" ] else [ ];

  simpleServiceUnits =
    let
      enabled = lib.filterAttrs (_: v: v ? enable && v.enable) (config.services or { });
      names = lib.attrNames enabled;
    in
    lib.filter (name: lib.hasAttr name (config.systemd.services or { })) names;

  wantedByUnits =
    let
      services = config.systemd.services or { };
      isWanted =
        _name: svc:
        let
          wantedBy = svc.wantedBy or (svc.unitConfig.WantedBy or [ ]);
        in
        lib.any (t: t == "multi-user.target" || t == "graphical.target") wantedBy;
      notOneshot =
        _name: svc:
        let
          svcType = svc.serviceConfig.Type or "";
        in
        svcType != "oneshot";
      wanted = lib.filterAttrs isWanted services;
      nonOneshot = lib.filterAttrs notOneshot wanted;
    in
    lib.attrNames nonOneshot;

  autoUnits = normalize (
    vaultUnits
    ++ quadletUnits
    ++ exporterUnits
    ++ tsnsrvUnits
    ++ immichUnits
    ++ sambaUnits
    ++ simpleServiceUnits
    ++ wantedByUnits
  );

  manualUnits = normalize (cfg.restartUnits or [ ]);
  excludedUnits = normalize (cfg.restartUnitsExclude or [ ]);

  allUnits = if cfg.restartUnitsAuto then lib.unique (manualUnits ++ autoUnits) else manualUnits;

  finalUnits = lib.subtractLists excludedUnits allUnits;

  unitNames = map (name: "${name}.service") finalUnits;
in
{
  options.my-services = {
    restartUnits = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra systemd service units to include in repo-services.target (names without .service).";
    };

    restartUnitsAuto = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically populate repo-services.target from repo-configured services.";
    };

    restartUnitsExclude = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Systemd service units to exclude from repo-services.target (names without .service).";
    };
  };

  config = lib.mkIf (unitNames != [ ]) {
    systemd.targets."my.target" = {
      description = "Repo services";
      wants = unitNames;
    };
  };
}
