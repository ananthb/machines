_: {
  services.vault = {
    enable = true;
    address = "[::]:8200";
    storageBackend = "raft";
    storageConfig = ''
      path = "/var/lib/vault"
      node_id = "endeavour"
    '';
    extraConfig = ''
      ui = true
      disable_mlock = true
      api_addr = "http://endeavour:8200"
      cluster_addr = "http://endeavour:8201"
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/vault 0750 vault vault -"
  ];

}
