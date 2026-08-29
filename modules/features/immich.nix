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
    };

    config = lib.mkIf config.immich.enableServer {
      services.immich = {
        enable = true;
        host = "0.0.0.0";
        openFirewall = false;
      };

      networking.firewall.extraInputRules = ''
        ip saddr 100.64.0.0/10 tcp dport ${toString config.immich.port} accept
      '';
    };
  };
}
