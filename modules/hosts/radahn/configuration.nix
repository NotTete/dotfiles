{ self, inputs, ... }: {
  flake.nixosModules.radahnConfiguration = { pkgs, lib, ...}: {
    imports = [
      self.nixosModules.radahnHardware
      self.nixosModules.displayManager
    ];

    boot = {
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
    };

    system.stateVersion = "26.05";
  };
}

