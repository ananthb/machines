{
  pkgs,
  ...
}:
let
  calibrePort = 8086;
  libraryDir = "/srv/media/books";
in
{
  users.groups.calibre = { };
  users.users.calibre = {
    isSystemUser = true;
    group = "calibre";
    home = libraryDir;
    createHome = true;
  };

  systemd.tmpfiles.rules = [
    "d ${libraryDir} 2775 calibre calibre - -"
  ];

  systemd.services.calibre-server = {
    description = "Calibre Content Server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      User = "calibre";
      Group = "calibre";
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'if [ ! -f ${libraryDir}/metadata.db ]; then ${pkgs.calibre}/bin/calibredb list --with-library ${libraryDir} >/dev/null; fi'";
      ExecStart = "${pkgs.calibre}/bin/calibre-server --port ${toString calibrePort} --listen-on 0.0.0.0 --with-library ${libraryDir}";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  networking.firewall.allowedTCPPorts = [ calibrePort ];
}
