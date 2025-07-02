{
  pkgs,
  system,
  username,
  inputs,
  ...
}:

{

  imports = [

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${username} = {
        imports = [
          ../home/common.nix
          ../home/linux.nix
        ];
      };
      home-manager.extraSpecialArgs = {
        inherit username inputs system;
      };
    }

  ];

  nixpkgs.config.allowUnfree = true;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.auto-optimise-store = true;
  nix.gc.automatic = true;
  nix.gc.dates = "weekly";

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = system;

  users.users.${username} = {
    name = username;
    home = "/home/" + username;
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "libvirtd"
      "systemd-journal"
    ];
  };

  environment.shells = [ pkgs.fish ];

  programs.fish.enable = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    nixfmt-rfc-style
    mosh
  ];
}
