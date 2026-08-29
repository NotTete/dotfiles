{ self, inputs, ... }: {
  flake.nixosModules.searxng = { config, lib, pkgs, ... }:
  let
    secretKeyName = "searxng-secret-${config.networking.hostName}";
  in {
    imports = [ inputs.sops-nix.nixosModules.sops ];

    options.searxng = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable the SearXNG meta search engine.

          The server listener binds on all interfaces but the firewall only
          accepts traffic coming from the tailscale network (100.64.0.0/10),
          so it is only reachable through the tailnet.
        '';
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
        description = "Port SearXNG will listen on (only reachable via tailscale).";
      };
    };

    config = lib.mkIf config.searxng.enable {
      sops.secrets.${secretKeyName} = {
        sopsFile = ../../secrets/secrets.yaml;
      };

      services.searx = {
        enable = true;
        openFirewall = false;
        settings = {
          use_default_settings = true;
          server = {
            port = config.searxng.port;
            bind_address = "0.0.0.0";
            # Secret key read from the sops secret at runtime.
            secret_key = "$SEARX_SECRET_KEY";
          };
        };
        environmentFile = config.sops.secrets.${secretKeyName}.path;
      };

      networking.firewall.extraInputRules = ''
        ip saddr 100.64.0.0/10 tcp dport ${toString config.searxng.port} accept
      '';
    };
  };
}
