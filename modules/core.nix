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

  config = lib.mkIf cfg.enable {
    # Setup GC, store optimiser and flakes cli stuff
    nix = lib.mkIf cfg.nix {
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

    # Networking & Hardware Defaults
    networking.networkmanager.enable = lib.mkIf cfg.networking true;
    hardware.bluetooth.enable = lib.mkIf cfg.networking true;
    hardware.enableRedistributableFirmware = lib.mkIf cfg.networking true;
    services.fwupd.enable = lib.mkIf cfg.networking true;

    # Audio via PipeWire
    services.pipewire = lib.mkIf cfg.audio {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Printing
    services.printing.enable = lib.mkIf cfg.printing true;
    services.avahi = lib.mkIf cfg.printing {
      enable = true;
      nssmdns4 = true;
    };

    # System Auto-updates
    system.autoUpgrade = lib.mkIf cfg.updates {
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

    # Locale & Timezone
    time.timeZone = lib.mkIf cfg.locale "Europe/London";
    i18n = lib.mkIf cfg.locale {
      defaultLocale = "en_GB.UTF-8";
      extraLocaleSettings.LC_ALL = "en_GB.UTF-8";
    };

    # Home manager
    home-manager.useGlobalPkgs = lib.mkIf cfg.homeManager true;
    home-manager.useUserPackages = lib.mkIf cfg.homeManager true;
  };
}
