{ self, lib, ... }:
{
  # Install the *wrapped* hyprland into systems that import this module,
  # and register it as a display-manager (ly) Wayland session.
  flake.nixosModules.hyprland = { pkgs, ... }: {
    environment.systemPackages = [ self.packages.${pkgs.system}.hyprland ];
    services.displayManager.sessionPackages = [ self.packages.${pkgs.system}.hyprland ];
  };
}
