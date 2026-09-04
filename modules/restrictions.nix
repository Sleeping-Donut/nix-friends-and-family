{ config, lib, ... }:
let
  cfg = config.nixFriendsAndFamily.restrictions;
  cfgSafer = cfg.childSaferNetwork;
in
{
  options.nixFriendsAndFamily.restrictions = {
    enable = lib.mkEnableOption "Enable restrictions module";

    flatpakNeedsWheel = lib.mkEnableOption "Require wheel/admin auth for Flatpak actions";

    childSaferNetwork = {
      enable = lib.mkEnableOption "Parental control DNS filtering and domain redirection";

      ignoreDhcpDns = lib.mkEnableOption "Ignore the DHCP provided DNS server."
        // { default = true; };

      blockTikTok = lib.mkEnableOption "Block TikTok and related CDN domains."
        // { default = true; };

      youtubeRestrictedMode = lib.mkOption {
        type = lib.types.enum [ "strict" "moderate" "block" "none" ];
        default = "strict";
        description = "Force YouTube Restricted Mode via Google VIP DNS redirection.";
      };

      childFriendlyDns = lib.mkEnableOption "Use Cloudflare Family DNS (1.1.1.3) upstream to filter adult content and malware."
        // { default = true; };

      browserLockdownUsers = lib.mkOption { # TODO: split to browserLockdown = { users, restriction1... }
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of usernames that should have locked-down browser policies forcibly mounted into their session namespace.";
      };
    };
  };

  config = lib.mkMerge [
    # Polkit Restriction: Require wheel for Flatpak management
    (lib.mkIf (cfg.enable && cfg.flatpakNeedsWheel) (lib.mkDefault {
      security.polkit = lib.mkMerge [
        {
          extraConfig = ''
            if (action.id.startsWith("org.freedesktop.Flatpak.") && !subject.isInGroup("wheel")) {
              return polkit.Result.AUTH_ADMIN;
            }
          '';
        }
      ];
    }))

    # DNS & Network Restrictions via dnsmasq
    (lib.mkIf (cfg.enable && cfgSafer.enable) (lib.mkDefault {
      # Force NetworkManager to put local dnsmasq at the top of /etc/resolv.conf ahead of DHCP DNS
      networking.networkmanager.insertNameservers = [ "127.0.0.1" ];

      services.dnsmasq = {
        enable = true;
        settings = {
          no-resolv = lib.mkIf cfgSafer.ignoreDhcpDns true;

          server = lib.optionals cfgSafer.childFriendlyDns [
            "1.1.1.3"
            "1.0.0.3"
            "2606:4700:4700::1113"
            "2606:4700:4700::1003"
          ];

          address = let
            ytIp = if cfgSafer.youtubeRestrictedMode == "strict" then "216.239.38.120"
              else if cfgSafer.youtubeRestrictedMode == "moderate" then "216.239.38.119"
              else if cfgSafer.youtubeRestrictedMode == "block" then "0.0.0.0"
              else null;
          in (
            lib.optionals cfgSafer.blockTikTok [
              "/tiktok.com/0.0.0.0"
              "/tiktokv.com/0.0.0.0"
              "/tiktokcdn.com/0.0.0.0"
              "/byteoversea.com/0.0.0.0"
            ]
            ++
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
    }))

    # TODO: broswer policy lockdown
    # firefoxPolicyDir = pkgs.writeTextDir "firefox/policies/policies.json" (builtins.toJSON {
    # and chrome, zen, helium etc
    # pam namespace policies to specified users
  ];
}

