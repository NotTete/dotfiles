{ self, inputs, ... }:
{
  flake.nixosModules.terminal = { pkgs, ... }: {
    environment.systemPackages = [ self.packages.${pkgs.system}.kitty ];
  };
}
