{ self, inputs, ... }: {
  flake.nixosModules.navidrome = { config, lib, pkgs, ... }: {
    options.navidrome = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable the Navidrome music server.

          The server binds on all interfaces but the firewall only accepts
          traffic coming from the tailscale network (100.64.0.0/10), so it is
          only reachable through the tailnet.
        '';
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 4533;
        description = "Port Navidrome will listen on (only reachable via tailscale).";
      };
      musicFolder = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/music";
        description = "Directory Navidrome scans for music (also where tools like MusicGrabber drop files).";
      };
    };

    config = lib.mkIf config.navidrome.enable {
      services.navidrome = {
        enable = true;
        openFirewall = false;
        settings = {
          Address = "0.0.0.0";
          Port = config.navidrome.port;
          MusicFolder = config.navidrome.musicFolder;
        };
      };

      # The music folder is shared between navidrome (scans it), slskd (shares
      # it) and the user (adds songs). Navidrome creates it as navidrome:navidrome
      # 700, which locks everyone else out, so fix the perms after it starts:
      # group-writable + setgid so new files inherit the navidrome group.
      users.users.tete.extraGroups = [ "navidrome" ];

      systemd.services.fix-music-perms = {
        description = "Fix permissions on the shared music folder";
        after = [ "navidrome.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          mkdir -p ${config.navidrome.musicFolder}
          chmod 2775 ${config.navidrome.musicFolder}
          chown navidrome:navidrome ${config.navidrome.musicFolder}
        '';
      };

      # Only allow traffic from the tailnet, mirroring the immich/searxng modules.
      networking.firewall.extraInputRules = ''
        ip saddr 100.64.0.0/10 tcp dport ${toString config.navidrome.port} accept
      '';
    };
  };
}
