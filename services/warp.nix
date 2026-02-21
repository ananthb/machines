_: {
  # WARP must be manually set up in proxy mode listening on port 8888.
  # This involves registering a new identity, accepting the tos,
  # setting the mode to proxy, and then setting proxy port to 8888.
  services.cloudflare-warp.enable = true;
  services.cloudflare-warp.openFirewall = false;

}
