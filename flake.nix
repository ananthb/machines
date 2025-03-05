{
  description = "A SecureBoot-enabled NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";

      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.11";
      # If you are not running an unstable channel of nixpkgs,
      # select the corresponding branch of nixvim.
      # url = "github:nix-community/nixvim/nixos-23.05";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      lanzaboote,
      home-manager,
      nixvim,
      ...
    }@inputs:
    let
      mkPkgs =
        sys:
        import nixpkgs {
          system = sys;
          config = {
            allowUnfree = true;
          };
        };
    in

    {
      nixosConfigurations = {
        defiant =
          let
            hostname = "defiant";
            system = "x86_64-linux";
            username = "ananth";
          in
          nixpkgs.lib.nixosSystem {
            inherit system;

            specialArgs = inputs // {
              pkgs = mkPkgs system;
              hostname = hostname;
            };

            modules = [
              lanzaboote.nixosModules.lanzaboote
              (import ./hosts/defiant)

              home-manager.nixosModules.home-manager
              {
                home-manager = {
                  extraSpecialArgs = {
                    inherit username inputs system;
                  };
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  users.${username} = import ./home.nix;
                };
              }
            ];
          };
      };
    };
}
