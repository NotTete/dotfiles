{ self, inputs, ... }: {
  flake.nixosModules.git = { config, ... }: {
    programs.git = {
      enable = true;
      config = {
        init.defaultBranch = "main";
        user.name = config.preferences.user.nick;
        user.email = config.preferences.user.email;
      };
    };
  };
}
