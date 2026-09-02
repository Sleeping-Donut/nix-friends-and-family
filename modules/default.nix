{ config, lib, pkgs, ... }: {
      imports = [
        ./core.nix
        ./boot.nix
        ./desktop.nix
        ./restrictions.nix
      ];

      options.nixFriendsAndFamily = {
        enable = lib.mkEnableOption "Enable Shared Base";

        desktop = lib.mkOption {
          type = lib.types.enum [ "gnome" "kde" "none" ];
          default = "kde";
          description = "Desktop Environment selection";
        };

        bootloader = lib.mkOption {
          type = lib.types.enum [ "systemd-boot" "grub" "limine" ];
          default = "systemd-boot";
          description = "Bootloader selection";
        };
        bootTheme = lib.mkOption {
          type = lib.types.enum [ "oem" "breeze" ];
          default = "oem";
          description = "Boot splash theme: 'oem' = firmware/BIOS logo (bgrt), 'breeze' = Nix snowflake spinner";
        };

        restrictions = {
          flatpakNeedsWheel = lib.mkEnableOption "Require wheel/admin auth for Flatpak actions";

          childSaferNetwork = {
            enable = lib.mkEnableOption "Parental control DNS filtering and domain redirection";
            blockTikTok = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Block TikTok and related CDN domains.";
            };

            youtubeRestrictedMode = lib.mkOption {
              type = lib.types.enum [ "strict" "moderate" "block" "none" ];
              default = "strict";
              description = "Force YouTube Restricted Mode via Google VIP DNS redirection.";
            };

            childFriendlyDns = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Use Cloudflare Family DNS (1.1.1.3) upstream to filter adult content and malware.";
            };
          };
        };
      };
    };

