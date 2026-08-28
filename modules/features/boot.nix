{ self, inputs, ... }: {
  flake.nixosModules.boot = {...}: {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
