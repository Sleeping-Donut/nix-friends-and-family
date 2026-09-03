{ lib, ... }: {

  options.nixFriendsAndFamily = {
    enable = lib.mkEnableOption "Enable Shared Base";
  };

  imports = [
    ./core.nix
    ./boot.nix
    ./desktop.nix
    ./restrictions.nix
  ];
}

