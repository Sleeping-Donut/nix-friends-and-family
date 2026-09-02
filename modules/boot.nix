{ config, lib, pkgs, ... }:
let
  cfg = config.nixFriendsAndFamily;
  isBoot = boot: cfg.bootloader == boot;
in
{
  config = lib.mkIf cfg.enable {
    # Bootloader Selection
    boot.loader.systemd-boot = lib.mkIf (isBoot "systemd-boot") {
      enable = true;
      editor = false;
    };
    boot.loader.grub = lib.mkIf (isBoot "grub") {
      enable = true;
      device = "nodev";
      efiSupport = true;
    };
    boot.loader.efi.canTouchEfiVariables = lib.mkIf (isBoot "grub" || isBoot "systemd-boot") true;
    boot.loader.limine.enable = lib.mkIf (isBoot "limine") true;

    # Boot splash (hide systemd boot messages from users)
    boot.plymouth = let
      themeMap = {
        oem = { theme = "bgrt"; };
        "oem-nix" = { theme = "nixos-bgrt"; pkgs = [ pkgs.nixos-bgrt-plymouth ]; };
        breeze = { theme = "breeze"; pkgs = [ pkgs.kdePackages.breeze-plymouth ]; };
      };
      selectedTheme = themeMap.${cfg.bootTheme};
    in {
      enable = true;
      theme = selectedTheme.theme;
      themePackages = selectedTheme.pgks ? [];
    };
  }
}

