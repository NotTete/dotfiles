{ self, inputs, lib, ... }: {
  flake.nixosModules.lidarr = { config, lib, pkgs, ... }: {
    options.lidarr = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable Lidarr (nightly) as a container.

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
      # Nightly (develop) Lidarr, run in a container because self-contained
      # .NET is painful to patchelf on NixOS. linuxserver image. Each app keeps
      # its own identity; the shared music folder is a dedicated `music` group,
      # so Lidarr runs as uid 992 with that group as its primary GID.
      virtualisation.oci-containers = {
        backend = "podman";
        containers."lidarr-nightly" = {
          image = "docker.io/linuxserver/lidarr:nightly";
          autoStart = true;
          ports = [ "${toString config.lidarr.port}:8686" ];
          volumes = [
            "/var/lib/lidarr:/config"
            "${config.lidarr.musicFolder}:/music"
            "/var/lib/slskd/downloads:/var/lib/slskd/downloads"
          ];
          environment = {
            PUID = "992"; # dedicated lidarr uid
            PGID = "986"; # music group gid
            TZ = "Atlantic/Canary";
          };
          extraOptions = [ "--pull=always" ];
        };
      };

      # Create Lidarr's config dir owned by its container user + the music group.
      systemd.tmpfiles.rules = [
        "d /var/lib/lidarr 0755 992 music - -"
      ];

      # Only allow traffic from the tailnet, mirroring the other service modules.
      networking.firewall.extraInputRules = ''
        ip saddr 100.64.0.0/10 tcp dport ${toString config.lidarr.port} accept
      '';
    };
  };
}
