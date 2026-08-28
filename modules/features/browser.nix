{ self, inputs, lib, ... }:
{
  flake.nixosModules.browser = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      mullvad-browser
      tor-browser
    ];
  };
}
