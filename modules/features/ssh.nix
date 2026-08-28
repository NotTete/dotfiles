{ self, inputs, ... }: {
  flake.nixosModules.ssh = { config, lib, pkgs, ... }: {
    services.openssh = {
      enable = true;
      startAgent = true;
    };
  };
}
