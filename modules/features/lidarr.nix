{ self, inputs, ... }: {
  flake.nixosModules.lidarr = { config, lib, pkgs, ... }: {
    options.lidarr = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable the Lidarr music download manager.

          The server binds on all interfaces but the firewall only accepts
          traffic coming from the tailscale network (100.64.0.0/10), so it is
          only reachable through the tailnet.
        '';
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 8686;
        description = "Port Lidarr will listen on (only reachable via tailscale).";
      };
      musicFolder = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/music";
        description = "Root folder where Lidarr manages the music library (shared with navidrome/slskd).";
      };
    };

    config = lib.mkIf config.lidarr.enable {
      services.lidarr = {
        enable = true;
        openFirewall = false;
        settings = {
          server = {
            port = config.lidarr.port;
            bindaddress = "*";
          };
        };
      };

      # Let the lidarr user write into the shared music folder so it can manage
      # the library (the navidrome module makes it group-writable).
      users.users.lidarr.extraGroups = [ "navidrome" ];

      # Only allow traffic from the tailnet, mirroring the immich/searxng/navidrome modules.
      networking.firewall.extraInputRules = ''
        ip saddr 100.64.0.0/10 tcp dport ${toString config.lidarr.port} accept
      '';
    };
  };
}
