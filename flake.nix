{
  description = "Base NixOS module for friends and family";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = inputs@{ self, nixpkgs, nixos-hardware, nix-flatpak, home-manager, ... }: {
    templates.default = {
      path = ./template;
      description = "Template to make semi-managed system config";
      welcomeText = ''
        Before building, please:
        1. Rename PC_NAME_HERE and USERNAME_HERE in flake.nix
        2. Set your correct COMPUTER_MODEL from: https://github.com/NixOS/nixos-hardware/blob/master/flake.nix
        3. Run `nixos-generate-config --root /` and copy the generated hardware-configuration.nix into the directory.
        4. To enable auto-upgrades, ensure these config files are in /etc/nixos
        Full info in README
      '';
    };

    nixosModules.nixFriendsAndFamily = { config, lib, pkgs, ... }: {
      imports = [
        nix-flatpak.nixosModules.nix-flatpak
        home-manager.nixosModules.home-manager
        ./modules
      ];
    };
  };
}
