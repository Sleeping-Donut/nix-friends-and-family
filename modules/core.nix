{ config, lib, ... }:
let
  cfg = config.nixFriendsAndFamily;
in
{
  config = lib.mkIf cfg.enable {
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

    # Networking & Hardware Defaults
    networking.networkmanager.enable = true;
    hardware.bluetooth.enable = true;
    hardware.enableRedistributableFirmware = true;
    services.fwupd.enable = true;

    # Audio via PipeWire
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Printing
    services.printing.enable = true;
    services.avahi = {
      enable = true;
      nssmdns4 = true;
    };

    # System Auto-updates
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

    # Locale & Timezone
    time.timeZone = "Europe/London";
    i18n = {
      defaultLocale = "en_GB.UTF-8";
      extraLocaleSettings.LC_ALL = "en_GB.UTF-8";
    };

    # Home manager
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
  };
}
