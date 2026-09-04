{ config, lib, ... }:
let
  cfg = config.nixFriendsAndFamily.restrictions;
  cfgSafer = cfg.childSaferNetwork;
in
{
  options.nixFriendsAndFamily.restrictions = {
    flatpakNeedsWheel = lib.mkEnableOption "Require wheel/admin auth for Flatpak actions";

    childSaferNetwork = {
      enable = lib.mkEnableOption "Parental control DNS filtering and domain redirection";

      blockTikTok = lib.mkEnableOption "Block TikTok and related CDN domains."
        // { default = true; };

      youtubeRestrictedMode = lib.mkOption {
        type = lib.types.enum [ "strict" "moderate" "block" "none" ];
        default = "strict";
        description = "Force YouTube Restricted Mode via Google VIP DNS redirection.";
      };

      childFriendlyDns = lib.mkEnableOption "Use Cloudflare Family DNS (1.1.1.3) upstream to filter adult content and malware."
        // { default = true; };
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkDefault {
    security.polkit = lib.mkMerge [

    # Polkit Restriction: Require wheel for Flatpak management
      (lib.mkIf cfg.restrictions.flatpakNeedsWheel {
        extraConfig = ''
          if (action.id.startsWith("org.freedesktop.Flatpak.") && !subject.isInGroup("wheel")) {
            return polkit.Result.AUTH_ADMIN;
          }
        '';
      })

    ];

    # Force NetworkManager to put local dnsmasq at the top of /etc/resolv.conf ahead of DHCP DNS
    networking.networkmanager.insertNameservers = lib.mkIf cfgSafer.enable [ "127.0.0.1" ];

    # DNS & Network Restrictions via dnsmasq
    services.dnsmasq = lib.mkIf cfgSafer.enable {
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
  });
}

