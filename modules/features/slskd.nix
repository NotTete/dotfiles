{ self, inputs, ... }: {
  flake.nixosModules.slskd = { config, lib, pkgs, ... }:
  let
    secretKeyName = "slskd-credentials-${config.networking.hostName}";
  in {
    imports = [ inputs.sops-nix.nixosModules.sops ];

    options.slskd = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable the slskd Soulseek client/server.

          The web interface binds on all interfaces but the firewall only
          accepts traffic coming from the tailscale network (100.64.0.0/10),
          so it is only reachable through the tailnet.
        '';
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 5030;
        description = "Port the slskd web interface listens on (only reachable via tailscale).";
      };
      listenPort = lib.mkOption {
        type = lib.types.port;
        default = 50300;
        description = "Port slskd listens on for incoming Soulseek connections.";
      };
      openListenPort = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to open the Soulseek listen port in the firewall so other
          peers can reach this node directly. Disabled by default: slskd can
          still browse/search/download through the network, but incoming
          connections from other peers are blocked.
        '';
      };
      musicFolder = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/music";
        description = "Directory slskd shares on the Soulseek network.";
      };
      downloadFolder = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/slskd/downloads";
        description = "Directory where completed downloads are stored.";
      };
      incompleteFolder = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/slskd/incomplete";
        description = "Directory where in-progress downloads are stored.";
      };
    };

    config = lib.mkIf config.slskd.enable {
      sops.secrets.${secretKeyName} = {
        sopsFile = ../../secrets/secrets.yaml;
      };

      services.slskd = {
        enable = true;
        openFirewall = config.slskd.openListenPort;
        # Credentials (Soulseek + web UI) are read from the sops secret at
        # runtime, keeping them out of the world-readable nix store.
        environmentFile = config.sops.secrets.${secretKeyName}.path;
        settings = {
          web.port = config.slskd.port;
          soulseek.listen_port = config.slskd.listenPort;
          shares.directories = [ config.slskd.musicFolder ];
          directories = {
            downloads = config.slskd.downloadFolder;
            incomplete = config.slskd.incompleteFolder;
          };
        };
      };

      # Only allow traffic from the tailnet, mirroring the immich/searxng/navidrome modules.
      networking.firewall.extraInputRules = ''
        ip saddr 100.64.0.0/10 tcp dport ${toString config.slskd.port} accept
      '';
    };
  };
}
