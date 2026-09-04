{ config, lib, ... }:
let
  cfg = config.nixFriendsAndFamily.core;
in
{
  options.nixFriendsAndFamily.core = {
    enable = lib.mkEnableOption "Enable Options and defaults for core stuff";
    nix = lib.mkEnableOption "Enable Options and defaults for nix" // { default = true; };
    networking = lib.mkEnableOption "Enable Options and defaults for networking" // { default = true; };
    printing = lib.mkEnableOption "Enable Options and defaults for printing" // { default = true; };
    audio = lib.mkEnableOption "Enable Options and defaults for audio" // { default = true; };
    updates = lib.mkEnableOption "Enable Options and defaults for updates" // { default = true; };
    locale = lib.mkEnableOption "Enable Options and defaults for locale/timezone" // { default = true; };
    homeManager = lib.mkEnableOption "Enable Options and defaults for home manager" // { default = true; };
  };

  config = lib.mkMerge [
    # Setup GC, store optimiser and flakes cli stuff
    (lib.mkIf (cfg.enable && cfg.nix) (lib.mkDefault {
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
    }))

    # Networking & Hardware Defaults
    (lib.mkIf (cfg.enable && cfg.networking) (lib.mkDefault {
      networking.networkmanager.enable = true;
      hardware.bluetooth.enable = true;
      hardware.enableRedistributableFirmware = true;
      services.fwupd.enable = true;
    }))

    # Audio via PipeWire
    (lib.mkIf (cfg.enable && cfg.audio) (lib.mkDefault {
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };
    }))

    # Printing
    (lib.mkIf (cfg.enable && cfg.printing) (lib.mkDefault {
      services.printing.enable = true;
      services.avahi = {
        enable = true;
        nssmdns4 = true;
      };
    }))

    # System Auto-updates
    (lib.mkIf (cfg.enable && cfg.updates) (lib.mkDefault {
      system.autoUpgrade = {
        enable = true;
        flake = "/etc/nixos";
        flags = [
          "--update-input" "nix-friends-and-family"
          "--no-write-lock-file"
        ];
        dates = "03:00";
        randomizedDelaySec = "45min";
        allowReboot = false;
        operation = "boot";
      };
    }))

    # Locale & Timezone
    (lib.mkIf (cfg.enable && cfg.locale) (lib.mkDefault {
      time.timeZone = "Europe/London";
      i18n = {
        defaultLocale = "en_GB.UTF-8";
        extraLocaleSettings.LC_ALL = "en_GB.UTF-8";
      };
    }))

    # Home manager
    (lib.mkIf (cfg.enable && cfg.homeManager) (lib.mkDefault {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    }))
  ];
}
