{ self, inputs, ... }: {
  flake.nixosModules.git = {...}: {
    programs.git = {
      init.defaultBranch = "main";
      enable = true;
      config = {
        user.name = "NotTete";
        user.email = "55021970+NotTete@users.noreply.github.com";
      };
    };
  };
}
