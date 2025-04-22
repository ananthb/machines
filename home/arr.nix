{ pkgs, ... }: { home.packages = with pkgs; [ radarr sonarr prowlarr ]; }
