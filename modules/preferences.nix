{ self, inputs, ... }: {
  flake.nixosModules.preferences = { config, lib, ... }: {
    options.preferences = {
      # Mandatory: must be set per host (see assertion below).
      hostName = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Hostname of this machine.";
      };

      locale = lib.mkOption {
        type = lib.types.str;
        default = "es_ES.UTF-8";
      };
      timeZone = lib.mkOption {
        type = lib.types.str;
        default = "Atlantic/Canary";
      };

      keyboardLayout = lib.mkOption {
        type = lib.types.str;
        default = "es";
      };

      user = lib.mkOption {
        type = lib.types.attrs;
        default = {
          nick = "NotTete";
          email = "55021970+NotTete@users.noreply.github.com";
        };
      };
    };

    config = {
      assertions = [
        {
          assertion = config.preferences.hostName != "";
          message = "preferences.hostName is mandatory and must be set for this host.";
        }
      ];
    };
  };
}
