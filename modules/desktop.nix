{ config, lib, pkgs, ... }:
let
  cfg = config.nixFriendsAndFamily.desktop;
  isGnome = cfg.de == "gnome";
  isKde = cfg.de == "kde";
in
{
  options.nixFriendsAndFamily.desktop = {
    enable = lib.mkEnableOption "Enable Options and defaults for desktop stuff";
    de = lib.mkOption {
      type = lib.types.enum [ "gnome" "kde" "none" ];
      default = "none";
      description = "Desktop Environment selection";
    };
    flatpak = lib.mkEnableOption "Enable Options and defaults for flatpak" // { default = true; };
  };

  config = lib.mkMerge [
    # Flatpak Configuration
    (lib.mkIf cfg.enable (lib.mkDefault {
      services.flatpak = {
        enable = true;
        update = {
          auto = {
            enable = true;
            onCalendar = "weekly";
          };
        };
        remotes = [
          { name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }
        ];
        packages = [
          "io.github.kolunmi.Bazaar"
        ] ++ lib.optionals isGnome [ "com.github.tchx84.Flatseal" ];
      };

      # Extra Packages for the Desktops
      environment.systemPackages = [ ] ++ lib.optionals isKde [
        pkgs.kdePackages.kpipewire
        pkgs.kdePackages.flatpak-kcm
      ];
    }))

    # GNOME Configuration
    (lib.mkIf (cfg.enable && isGnome) (lib.mkDefault {
      services.displayManager.gdm.enable = true;
      services.desktopManager.gnome.enable = true;
      services.gnome = {
        core-developer-tools.enable = false;
        games.enable = false;
      };
    }))

    # KDE Configuration
    (lib.mkIf (cfg.enable && isKde) (lib.mkDefault {
      services.displayManager.plasma-login-manager.enable = true;
      services.desktopManager.plasma6.enable = true;
      programs.kdeconnect.enable = true;
    }))
  ];
}

