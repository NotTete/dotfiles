{ self, inputs, ... }: {
  flake.nixosModules.miquellaConfiguration = { pkgs, lib, config, ...}: {
    imports = [
      self.nixosModules.miquellaHardware
      self.nixosModules.terminal
      self.nixosModules.boot
      self.nixosModules.preferences
      self.nixosModules.locale
      self.nixosModules.git
      self.nixosModules.virtualization
      self.nixosModules.tailscale
      self.nixosModules.ssh
      self.nixosModules.shell
      self.nixosModules.immich
    ];

    # sops-nix needs the age private key to decrypt secrets at boot.
    sops.age.keyFile = "${config.users.users.tete.home}/.config/sops/age/keys.txt";

    ssh.enableServer = true;

    immich.enableServer = true;

    preferences = {
      hostName = "miquella";
      locale = "es_ES.UTF-8";
      timeZone = "Atlantic/Canary";
      keyboardLayout = "es";
    };

    nix.settings = {
      trusted-users = [ "root" "tete" ];
      experimental-features = [ "nix-command" "flakes" ];
    };

    networking = {
      hostName = config.preferences.hostName;
      networkmanager.enable = true;
    };

    time.timeZone = config.preferences.timeZone;

    users.users.tete = {
      isNormalUser = true;
      description = "tete";
      extraGroups = [ "networkmanager" "wheel" ];
    };

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      self.packages.${pkgs.system}.nvim
      btop
      devenv
      ripgrep
    ];

    system.stateVersion = "26.05";
  };
}

