{ self, inputs, ... }: {
  flake.nixosModules.immich = { config, lib, pkgs, ... }: {
    options.immich = {
      enableServer = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable the Immich photo service.

          The server listener binds on all interfaces but the firewall only
          accepts traffic coming from the tailscale network (100.64.0.0/10),
          so it is only reachable through the tailnet.
        '';
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 2283;
        description = "Port Immich will listen on (only reachable via tailscale).";
      };

      enableDesktop = lib.mkEnableOption ''
        a desktop entry that opens Immich in kiosk mode (fullscreen browser,
        no chrome). Useful for a photo-frame / kiosk setup.
      '';

      kioskUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://miquella:2283";
        description = "Immich URL to open in kiosk mode (reachable via tailscale).";
      };

      kioskBrowser = lib.mkOption {
        type = lib.types.package;
        default = pkgs.firefox;
        description = "Browser used for kiosk mode.";
      };

      # Dedicated profile so the kiosk instance doesn't clash with a normal
      # Firefox session (two Gecko instances can run side by side). Lives under
      # ~/.config so it's always writable by the user (unlike ~/.mozilla which
      # can end up root-owned).
      kioskProfile = lib.mkOption {
        type = lib.types.path;
        default = "${config.users.users.tete.home}/.config/immich-kiosk";
        description = "Absolute path to the Firefox profile used for the kiosk instance.";
      };
    };

    config = lib.mkMerge [
      (lib.mkIf config.immich.enableServer {
        services.immich = {
          enable = true;
          host = "0.0.0.0";
          openFirewall = false;
          machine-learning.environment = {
            MACHINE_LEARNING_MODEL_TTL = "60";
            MACHINE_LEARNING_CONCURRENCY = "1";
          };
        };

        networking.firewall.extraInputRules = ''
          ip saddr 100.64.0.0/10 tcp dport ${toString config.immich.port} accept
        '';
      })

      (lib.mkIf config.immich.enableDesktop (let
          mkKiosk = import ../../lib/kiosk.nix { inherit lib pkgs; };
        in {
          environment.systemPackages = mkKiosk {
            name = "immich";
            desktopName = "Immich";
            url = config.immich.kioskUrl;
            profile = config.immich.kioskProfile;
            browser = config.immich.kioskBrowser;
            icon = "camera-photo";
            comment = "Open Immich in kiosk mode";
          };
        }))
    ];
  };
}
