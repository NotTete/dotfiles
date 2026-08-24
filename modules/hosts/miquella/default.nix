{ self, inputs, ... }: {
  flake.nixosConfigurations.miquella = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.miquellaConfiguration
    ];
  };
}
