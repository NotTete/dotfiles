{ self, inputs, ... }: {
  flake.nixosModules.radahnConfiguration = { pkgs, lib, ...}: {
    imports = [
      self.nixosModules.radahnHardware
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    environment.systemPackages = with pkgs; [
      firefox
      vim
    ];
  };
}

