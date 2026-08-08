{
  description = "Local Machine Flake";

  inputs = {
    nix-friends-and-family.url = "github:Sleeping-Donut/nix-friends-and-family";
    nixpkgs.follows = "nix-friends-and-family/nixpkgs";
    nixos-hardware.follows = "nix-friends-and-family/nixos-hardware";
    home-manager.follows = "nix-friends-and-family/home-manager";
  };

  outputs = { self, nixpkgs, nix-friends-and-family, nixos-hardware, home-manager, ... }: {
    nixosConfigurations = {
      PC_NAME_HERE = nixpkgs.lib.nixosSystem { # <-- Change PC name
        system = "x86_64-linux";
        modules = [
          nix-friends-and-family.nixosModules.nixFriendsAndFamily
          ./hardware-configuration.nix

          # add your model from this list: https://github.com/NixOS/nixos-hardware/blob/master/flake.nix
          # nixos-hardware.nixosModules.COMPUTER_MODEL # <-- Change computer model

          {
            nixFriendsAndFamily.enable = true;
            nixFriendsAndFamily.desktop = "gnome";

            system.stateVersion = "26.05";
            networking.hostName = "PC_NAME_HERE"; # <-- Change PC name
            time.timezone = "Europe/London";

            users.users.USERNAME_HERE = { # <-- Change username
              isNormalUser = true;
              extraGroups = [ "wheel" "networkmanager" ];
            };
            # Make a home.nix to be added to the repo
            home-manager.users.USERNAME_HERE = import ./home.nix;
          }
        ];
      };
      default = self.nixosConfigurations.PC_NAME_HERE; # <-- Change PC name
    };
  };
}

