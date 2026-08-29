
{ self, inputs, ... }: {
  flake.nixosModules.shell = { config, pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      self.packages.${pkgs.system}.zsh
      eza
      fzf
    ];

    users.users.tete.shell = self.packages.${pkgs.system}.zsh;
  };
}
