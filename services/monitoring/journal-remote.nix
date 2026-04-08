# Centralized log collection via systemd journal-remote.
# Receives journals from all hosts via systemd-journal-upload
# (configured in nixos-common.nix). Logs stored per-host in
# /var/log/journal/remote/ and queryable with journalctl.
_: {
  networking.firewall.allowedTCPPorts = [19532];

  services.journald.remote = {
    enable = true;
    listen = "http";
    port = 19532;
    settings.Remote.SplitMode = "host";
  };
}
