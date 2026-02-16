_: hostname:
let
  hostFile = ../home/${hostname}.nix;
  hostDefault = ../home/${hostname}/default.nix;
in
if builtins.pathExists hostFile then
  hostFile
else if builtins.pathExists hostDefault then
  hostDefault
else
  throw "Missing Home Manager config for ${hostname} (expected ${toString hostFile} or ${toString hostDefault})"
