{ pkgs, ... }:
{
  home.packages = with pkgs; [
    socat
  ];
}
