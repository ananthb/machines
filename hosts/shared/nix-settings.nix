# Shared nix settings for all platforms (NixOS, Darwin, Garnix).
# nixpkgs.config (allowUnfree, overlays) is set in flake.nix via pkgsFor.
_: {
  nix = {
    settings = {
      experimental-features = "nix-command flakes";

      extra-substituters = [
        "https://cache.garnix.io"
      ];
      extra-trusted-public-keys = [
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
    };

    gc.automatic = true;
    optimise.automatic = true;
  };
}
