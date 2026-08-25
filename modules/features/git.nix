{ self, inputs, ... }: {
  flake.nixosModules.git = {...}: {
    programs.git = {
      enable = true;
      config = {
        init.defaultBranch = "main";
        user.name = "NotTete";
        user.email = "55021970+NotTete@users.noreply.github.com";
      };
    };
  };
}
