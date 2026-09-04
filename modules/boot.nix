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

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && isBoot "systemd-boot") (lib.mkDefault {
      boot.loader.systemd-boot = {
        enable = true;
        editor = false;
      };
    }))
    (lib.mkIf (cfg.enable && isBoot "grub") (lib.mkDefault {
      boot.loader.grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
      };
    }))
    (lib.mkIf (cfg.enable && isBoot "limine") (lib.mkDefault {
      boot.loader.limine.enable = true;
    }))
    (lib.mkIf (cfg.enable && (isBoot "grub" || isBoot "systemd-boot")) (lib.mkDefault {
      boot.loader.efi.canTouchEfiVariables = true;
    }))

    # Boot splash (hide systemd boot messages from users)
    (lib.mkIf cfg.enable (lib.mkDefault {
      boot.plymouth = let
        themeMap = {
          spinner = { theme = "spinner"; };
          oem = { theme = "bgrt"; };
          "oem-nix" = { theme = "nixos-bgrt"; pkgs = [ pkgs.nixos-bgrt-plymouth ]; };
          breeze = { theme = "breeze"; pkgs = [ pkgs.kdePackages.breeze-plymouth ]; };
        };
        selectedTheme = let
          isX86 = pkgs.stdenv.hostPlatform.isx86_64;
        in if isX86 then themeMap.${cfg.bootTheme} else themeMap.spinner;
      in {
        enable = true;
        theme = selectedTheme.theme;
        themePackages = selectedTheme.pkgs or [];
      };
    }))
  ];
}

