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

      config = let
        cfg = config.nixFriendsAndFamily;
        isGnome = cfg.desktop == "gnome";
        isKde = cfg.desktop == "kde";
        isBoot = loader: cfg.bootloader == loader;
      in lib.mkIf cfg.enable {

        # Setup GC, store optimiser and flakes cli stuff
        nix = {
          gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 14d";
          };
          settings = {
            auto-optimise-store = true;
            experimental-features = [ "nix-command" "flakes" ];
          };
        };

        # NetworkManager for WiFi/ethernet (needed for KDE/GNOME network applets)
        networking.networkmanager.enable = true;

        # Audio via PipeWire (KDE enables it itself; GNOME does not, so set for both)
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };

        # Bluetooth (harmless on machines without an adapter)
        hardware.bluetooth.enable = true;

        # CUPS printing + network printer discovery
        services.printing.enable = true;
        services.avahi.enable = true;
        services.avahi.nssmdns4 = true;

        # Firmware for WiFi/BT chips not otherwise covered by nixos-hardware
        hardware.enableRedistributableFirmware = true;

        # Firmware update service for laptops
        services.fwupd.enable = true;

        # Background Auto-Updates pulling from base repo
        system.autoUpgrade = {
          enable = true;
          flake = "/etc/nixos";
          flags = [
            "--update-input" "nix-friends-and-family"
            "--no-write-lock-file"
          ];
          dates = "03:00";
          randomizedDelaySec = "45min";
          allowReboot = false; # Let user reboot on their own time
          operation = "boot"; # apply generation next boot not immediately
        };

        time.timeZone = "Europe/London";
        i18n = {
          defaultLocale = "en_GB.UTF-8";
          extraLocaleSettings.LC_ALL = "en_GB.UTF-8";
        };

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
        boot.plymouth = {
          enable = true;
          theme = {
            oem = "bgrt";
            breeze = "breeze";
          }.${cfg.bootTheme};
        };

        # Setup Flatpaks and get store
        services.flatpak = {
          enable = true;
          update = {
            auto = {
              enable = true;
              onCalendar = "weekly";
            };
            onActivation = true;
          };
          remotes = [
            { name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }
          ];
          packages = [
            "io.github.kolunmi.Bazaar"
          ] ++ lib.optionals isGnome [ "com.github.tchx84.Flatseal" ];
        };

        environment.systemPackages = [ ] ++ lib.optionals isKde [
          pkgs.kdePackages.kpipewire
          pkgs.kdePackages.flatpak-kcm
        ];

        # Setup KDE (if selected)
        services.displayManager.plasma-login-manager.enable = lib.mkIf isKde true;
        services.desktopManager.plasma6.enable = lib.mkIf isKde true;
        programs.kdeconnect.enable = lib.mkIf isKde true;

        # Setup GNOME (if selected)
        services.displayManager.gdm.enable = lib.mkIf isGnome true;
        services.desktopManager.gnome.enable = lib.mkIf isGnome true;
        services.gnome = lib.mkIf isGnome {
            core-developer-tools.enable = false;
            games.enable = false;
        };

        security.polkit = lib.mkMerge [
          (lib.mkIf cfg.restrictions.flatpakNeedsWheel {
            extraConfig = ''
              if (action.id.startsWith("org.freedesktop.Flatpak.") && !subject.isInGroup("wheel")) {
                return polkit.Result.AUTH_ADMIN;
              }
            '';
          })
        ];

        # Child Safer Network
        networking.nameservers = lib.mkIf cfg.restrictions.childSaferNetwork.enable [ "127.0.0.1" "::1" ];
        networking.networkmanager.insertNameservers = lib.mkIf cfg.restrictions.childSaferNetwork.enable [ "127.0.0.1" ];
        services.dnsmasq = let
          cfgSafer = cfg.restrictions.childSaferNetwork;
        in lib.mkIf cfgSafer.enable {
          enable = true;
          settings = {
            # Ignore DHCP-provided DNS servers from routers so filtering cannot be bypassed
            no-resolv = true;

            # Upstream child-friendly DNS servers (Cloudflare Family)
            server = lib.optionals cfgSafer.childFriendlyDns [
              "1.1.1.3"
              "1.0.0.3"
              "2606:4700:4700::1113"
              "2606:4700:4700::1003"
            ];

            # Custom domain mappings
            address = let
              ytIp = if cfgSafer.youtubeRestrictedMode == "strict" then "216.239.38.120"
                else if cfgSafer.youtubeRestrictedMode == "moderate" then "216.239.38.119"
                else if cfgSafer.youtubeRestrictedMode == "block" then "0.0.0.0"
                else null;
            in (
              # Wildcard block TikTok and CDN domains
              lib.optionals cfgSafer.blockTikTok [
                "/tiktok.com/0.0.0.0"
                "/tiktokv.com/0.0.0.0"
                "/tiktokcdn.com/0.0.0.0"
                "/byteoversea.com/0.0.0.0"
              ]
              ++
              # Force YouTube domains to Google's Restricted Mode VIP
              lib.optionals (ytIp != null) [
                "/youtube.com/${ytIp}"
                "/www.youtube.com/${ytIp}"
                "/m.youtube.com/${ytIp}"
                "/youtubei.googleapis.com/${ytIp}"
                "/youtube.googleapis.com/${ytIp}"
                "/www.youtube-nocookie.com/${ytIp}"
              ]
            );
          };
        };

        # Configure home-manager
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      };
    };
  };
}
