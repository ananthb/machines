{
  inputs,
  system,
  username,
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
          ./home/common.nix
          ./home/linux.nix
        ];
      };
      home-manager.extraSpecialArgs = {
        inherit username inputs system;
      };
    }

  ];

  home.homeDirectory = "/home/${username}";

  programs.fish.interactiveShellInit = ''
    set fish_greeting ""
  '';
}
