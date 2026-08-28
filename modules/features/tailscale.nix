{ self, inputs, ... }: {
  flake.nixosModules.tailscale = { config, lib, pkgs, ... }:
  let
    # Secret key name follows the hostname: tailscale-key-<hostName>.
    # Each host needs the matching key in secrets/secrets.yaml.
    authKeyName = "tailscale-key-${config.networking.hostName}";
  in {
    # sops-nix decrypts secrets at boot and mounts them under /run/secrets.
    imports = [ inputs.sops-nix.nixosModules.sops ];

    sops.secrets.${authKeyName} = {
      sopsFile = ../../secrets/secrets.yaml;
    };

    services.tailscale = {
      enable = true;
      # Auth key from the sops secret (only needed for first-time auth).
      authKeyFile = config.sops.secrets.${authKeyName}.path;
      # Name the node after the configured hostname.
      extraUpFlags = [ "--hostname=${config.networking.hostName}" ];
    };
  };
}
