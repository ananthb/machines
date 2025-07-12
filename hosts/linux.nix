{
  pkgs,
  system,
  username,
  home-manager,
  nixvim,
  sops-nix,
  ...
}:

{

  imports = [

    home-manager.nixosModules.home-manager
    {
      home-manager.sharedModules = [
        sops-nix.homeManagerModules.sops
      ];
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${username} = {
        imports = [
          ../home/common.nix
          ../home/linux.nix
        ];
      };
      home-manager.extraSpecialArgs = {
        inherit username system nixvim;
      };
    }

  ];

  sops.age.sshKeyPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

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
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINu7u4V6khhhUvepvptel86DN3XMCwZVdQe/7P6WW1KmAAAAFXNzaDphbmFudGhzLXNzaC1rZXktMQ== ananth@yubikey-5c"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };

  environment.shells = [ pkgs.fish ];

  programs.fish.enable = true;
  programs.mosh.enable = true;

  services.fwupd.enable = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    nixfmt-rfc-style
    ghostty.terminfo
  ];
}
