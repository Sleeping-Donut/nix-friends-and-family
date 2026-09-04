{ config, lib, pkgs, ... }:
let
  cfg = config.nixFriendsAndFamily.boot;
  isBoot = boot: cfg.bootloader == boot;
in
{
  options.nixFriendsAndFamily.boot = {
    enable = lib.mkEnableOption "Enable Options and defaults for boot stuff";
    bootloader = lib.mkOption {
      type = lib.types.enum [ "systemd-boot" "grub" "limine" "none" ];
      default = "systemd-boot";
      description = "Bootloader selection";
    };
    bootTheme = lib.mkOption {
      type = lib.types.enum [ "spinner" "oem" "oem-nix" "breeze" ];
      default = "oem-nix";
      description =''
        Boot splash screen
        - "spinner": default plymouth theme, works on all
        - "oem": firmware/BIOS logo with circle spinner (bgrt)
        - "oem-nix": firmware/BIOS logo with snowflake spinner
        - "breeze": Nix snowflake spinner";
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkDefault (lib.mkMerge [
    # Bootloader Selection — each submodule gets its own mkIf block
    (lib.mkIf (isBoot "systemd-boot") {
      boot.loader.systemd-boot = {
        enable = true;
        editor = false;
      };
    })
    (lib.mkIf (isBoot "grub") {
      boot.loader.grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
      };
    })
    (lib.mkIf (isBoot "limine") {
      boot.loader.limine.enable = true;
    })
    (lib.mkIf (isBoot "grub" || isBoot "systemd-boot") {
      boot.loader.efi.canTouchEfiVariables = true;
    })

    # Boot splash (hide systemd boot messages from users)
    {
      boot.plymouth = let
        themeMap = {
          spinner = { theme = "spinner"; };
          oem = { theme = "bgrt"; };
          "oem-nix" = { theme = "nixos-bgrt"; pkgs = [ pkgs.nixos-bgrt-plymouth ]; };
          breeze = { theme = "breeze"; pkgs = [ pkgs.kdePackages.breeze-plymouth ]; };
        };
        selectedTheme = let
          isX86 = pkgs.stdenv.hostPlatform.isx86_64;
        in if isX86 then themeMap.${cfg.bootTheme} else themeMap.spinner; # dumb fallback for all platforms
      in {
        enable = true;
        theme = selectedTheme.theme;
        themePackages = selectedTheme.pkgs or [];
      };
    }
  ]));
}

