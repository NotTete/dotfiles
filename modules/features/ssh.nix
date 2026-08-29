{ self, inputs, ... }: {
  flake.nixosModules.ssh = { config, lib, pkgs, ... }: {
    options.ssh = {
      enableServer = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable the OpenSSH server (sshd).

          Set to true to allow incoming SSH connections, false to disable the
          server. The SSH client agent is always enabled regardless of this
          option.
        '';
      };
    };

    config = {
      services.openssh = {
        enable = config.ssh.enableServer;
        ports = [ 22 ];
        settings = {
          AllowUsers = [ "tete" ];
          PasswordAuthentication = false;
          PermitRootLogin = "no";
          X11Forwarding = false;
          ClientAliveInterval = 300;
          ClientAliveCountMax = 2;
        };

        extraConfig = ''
          Match LocalAddress 100.64.0.0/10
            AllowUsers tete
          Match LocalAddress !100.64.0.0/10
            DenyUsers *
        '';
      };

      programs.ssh = {
        startAgent = true;
      };

      users.users.tete.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOr/1FITmj4INwD1r8ZkyLlkrGvIt9ZM9+3FbQAPUp/+"
      ];
    };
  };
}
