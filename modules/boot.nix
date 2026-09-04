{ config, lib, pkgs, ... }:
let
  cfg = config.nixFriendsAndFamily.boot;
  isBoot = boot: cfg.bootloader == boot;
in
{
  options.nixFriendsAndFamily.boot = {
    enable = lib.mkEnableOption "Enable Options and defaults for boot stuff";
    bootloader = lib.mkOption {
      type = lib.types.enum [ "systemd-boot" "grub" "limine" ];
      default = "systemd-boot";
      description = "Bootloader selection";
    };
    bootTheme = lib.mkOption {
      type = lib.types.enum [ "oem" "oem-nix" "breeze" ];
      default = "oem-nix";
      description =''
        Boot splash screen
        - "oem": firmware/BIOS logo with circle spinner (bgrt)
        - "oem-nix": firmware/BIOS logo with snowflake spinner
        - "breeze": Nix snowflake spinner";
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkDefault {
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
      themePackages = selectedTheme.pkgs or [];
    };
  });
}

