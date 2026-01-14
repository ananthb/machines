{ config, lib, ... }:
{

  virtualisation.quadlet = {
    autoEscape = true;
    autoUpdate.enable = true;

    containers = {

      collabora-code = {
        containerConfig = {
          name = "collabora-code";
          image = "docker.io/collabora/code:latest";
          podmanArgs = [ "--privileged" ];
          autoUpdate = "registry";
          publishPorts = [ "9980:9980" ];
          environmentFiles = [ config.sops.templates."collabora/code.env".path ];
          environments = {
            extra_params = lib.concatStringsSep " " [
              "--o:logging.file[@enable]=false"
              "--o:admin_console.enable=true"
              "--o:ssl.enable=false"
              "--o:ssl.termination=true"
              "--o:net.service_root=/collabora-code"
            ];
          };
        };
        serviceConfig.Restart = "on-failure";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 9980 ];

  sops.templates."collabora/code.env" = {
    content = ''
      server_name=seafile.kedi.dev
      aliasgroup1=https://seafile.kedi.dev:443
      username=${config.sops.placeholder."collabora/code/username"}
      password=${config.sops.placeholder."collabora/code/password"}
      DONT_GEN_SSL_CERT=true
      TZ=Asia/Kolkata
    '';
  };

  sops.secrets = {
    "collabora/code/username" = { };
    "collabora/code/password" = { };
  };

}
