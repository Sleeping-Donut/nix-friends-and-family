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
    nixFriendsAndFamily = lib.mkDefault {
      core.enabled = true;
      boot.enabled = true;
      desktop.enabled = true;
    };
  };
}

