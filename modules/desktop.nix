{ config, lib, pkgs, ... }:
let
  cfg = config.nixFriendsAndFamily;
  isGnome = cfg.desktop == "gnome";
  isKde = cfg.desktop == "kde";
in
{
  options.nixFriendsAndFamily = {
    desktop = lib.mkOption {
      type = lib.types.enum [ "gnome" "kde" "none" ];
      default = "kde";
      description = "Desktop Environment selection";
    };
  };

  config = lib.mkIf cfg.enable {
    # Flatpak Configuration
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

    # GNOME Configuration
    services.displayManager.gdm.enable = lib.mkIf isGnome true;
    services.desktopManager.gnome.enable = lib.mkIf isGnome true;
    services.gnome = lib.mkIf isGnome {
        core-developer-tools.enable = false;
        games.enable = false;
    };

    # KDE Configuration
    services.displayManager.plasma-login-manager.enable = lib.mkIf isKde true;
    services.desktopManager.plasma6.enable = lib.mkIf isKde true;
    programs.kdeconnect.enable = lib.mkIf isKde true;

    # Extra Packages for the Desktops
    environment.systemPackages = [ ] ++ lib.optionals isKde [
      pkgs.kdePackages.kpipewire
      pkgs.kdePackages.flatpak-kcm
    ];
  }
}

