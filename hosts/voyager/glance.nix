{ ... }:

{
  services.glance = {
    enable = true;
    openFirewall = true;
    settings = {
      server = {
        host = "[::]";
        port = 8083;
      };
    };
  };
}
