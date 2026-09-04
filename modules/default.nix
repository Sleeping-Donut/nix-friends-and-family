{ config, lib, ... }:
let
  cfg = config.nixFriendsAndFamily;
in {
  options.nixFriendsAndFamily.recommended = lib.mkEnableOption "Enable recommended shared base config";

  imports = [
    ./core.nix
    ./boot.nix
    ./desktop.nix
    ./restrictions.nix
  ];

  config = lib.mkIf cfg.recommended {
    nixFriendsAndFamily = {
      core.enabled = lib.mkDefault true;
      boot.enabled = lib.mkDefault true;
      desktop.enabled = lib.mkDefault true;
    };
  };
}

