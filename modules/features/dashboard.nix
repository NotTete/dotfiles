{ self, inputs, ... }: {
  flake.nixosModules.dashboard = { config, lib, pkgs, ... }: {
    options.dashboard = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable the Dynacat dashboard.

          Dynacat is a fork of Glance, so it is run through the upstream
          `services.glance` NixOS module (which provides the systemd unit,
          hardening and secret handling) with the package overridden to the
          Dynacat binary. The server binds on all interfaces but the firewall
          only accepts traffic from the tailscale network (100.64.0.0/10), so
          it is only reachable through the tailnet.
        '';
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
        description = "Port the dashboard listens on (only reachable via tailscale).";
      };
    };

    config = lib.mkIf config.dashboard.enable {
      # Use the upstream glance module as a wrapper, but run the Dynacat binary.
      # Dynacat is a fork of Glance, so the config format and CLI are compatible
      # (it accepts `--config` and reads the same YAML).
      services.glance = {
        enable = true;
        package = self.packages.${pkgs.system}.dynacat;
        settings = {
          server = {
            host = "0.0.0.0";
            port = config.dashboard.port;
          };
          pages = [
            {
              name = "Home";
              columns = [
                {
                  size = "small";
                  widgets = [
                    {
                      type = "calendar";
                      first-day-of-week = "monday";
                    }
                    {
                      type = "rss";
                      limit = 10;
                      collapse-after = 3;
                      cache = "12h";
                      feeds = [
                        {
                          url = "https://selfh.st/rss/";
                          title = "selfh.st";
                          limit = 4;
                        }
                        {
                          url = "https://ciechanow.ski/atom.xml";
                        }
                        {
                          url = "https://www.joshwcomeau.com/rss.xml";
                          title = "Josh Comeau";
                        }
                      ];
                    }
                  ];
                }
                {
                  size = "full";
                  widgets = [
                    {
                      type = "group";
                      widgets = [
                        { type = "hacker-news"; }
                        { type = "lobsters"; }
                      ];
                    }
                    {
                      type = "weather";
                      location = "London, United Kingdom";
                      units = "metric";
                      hour-format = "12h";
                    }
                  ];
                }
              ];
            }
          ];
        };
      };

      # Only allow traffic from the tailnet, mirroring the immich/searxng/navidrome modules.
      networking.firewall.extraInputRules = ''
        ip saddr 100.64.0.0/10 tcp dport ${toString config.dashboard.port} accept
      '';
    };
  };
}
