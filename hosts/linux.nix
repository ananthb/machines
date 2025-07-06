{
  pkgs,
  system,
  username,
  home-manager,
  nixvim,
  ...
}:

{

  imports = [

    home-manager.nixosModules.home-manager
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
    openssh.authorizedKeys.keyFiles = [
      ../keys/ssh/id_ed25519_sk.pub
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

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    nixfmt-rfc-style
    ghostty.terminfo
  ];
}
