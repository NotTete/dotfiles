{ self, inputs, ... }: {
  flake.nixosModules.displayManager = {...}: {
    services.displayManager.ly = {
      enable = true;
    };
  };
}
