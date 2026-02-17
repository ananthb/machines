{ hostname, ... }:
{
  services.vault = {
    enable = true;
    address = "[::]:8200";
    storageBackend = "raft";
    storageConfig = ''
      node_id = "${hostname}"
    '';
    extraConfig = ''
      ui = true
      disable_mlock = true
      api_addr = "http://${hostname}:8200"
      cluster_addr = "http://${hostname}:8201"
    '';
  };

}
