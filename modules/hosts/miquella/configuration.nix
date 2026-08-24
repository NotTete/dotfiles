{ self, inputs, ... }: {
  flake.nixosModules.miquellaConfiguration = { pkgs, lib, ...}: {
    imports = [
      self.nixosModules.miquellaHardware
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    environment.systemPackages = with pkgs; [
      firefox
      vim
    ];
  };
}

