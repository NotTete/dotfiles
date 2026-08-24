{ self, inputs, ... }: {
  flake.nixosConfigurations.radahn = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.radahnConfiguration
    ];
  };
}
