{ self, inputs, lib, ... }:
{
  flake.nixosModules.radahnConfiguration = { config, lib, pkgs, ... }:
  let
    # Upstream HelixNotes flake ships a stale pnpm-deps hash; fix it here.
    helixnotes-patch = (inputs.helixnotes.packages.${pkgs.system}.default)
      .overrideAttrs (final: prev: {
        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit (prev) src;
          cargoRoot = "src-tauri";
          hash = "sha256-Lf/2f+fyOz9/2XanNxzjImAtSRoDvrRZjzifiql+yI8=";
        };
        pnpmDeps = prev.pnpmDeps.overrideAttrs {
          outputHash = "sha256-QutzaClzphlmmAgDX+Az4BHsTbu+byhwMoUF/uxdPsI=";
        };
        # The app's tauri window config (decorations:false) isn't always honoured
        # on Linux/GTK, so force the windows frameless at runtime.
        patches = (prev.patches or []) ++ [ ./patches/force-frameless.patch ];
      });
  in {
    imports = [
      self.nixosModules.radahnHardware
      self.nixosModules.boot
      self.nixosModules.gpu
      self.nixosModules.preferences
      self.nixosModules.locale
      self.nixosModules.displayManager
      self.nixosModules.git
      self.nixosModules.terminal
      self.nixosModules.hyprland
      self.nixosModules.browser
      self.nixosModules.virtualization
      self.nixosModules.tailscale
      self.nixosModules.ssh
    ];

    # sops-nix needs the age private key to decrypt secrets at boot.
    sops.age.keyFile = "${config.users.users.tete.home}/.config/sops/age/keys.txt";

    preferences = {
      hostName = "radahn";
      locale = "es_ES.UTF-8";
      timeZone = "Atlantic/Canary";
      keyboardLayout = "es";
    };

    gpu.mode = "wayland";
    # Takes too much time to build
    gpu.compute.enable = false;

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
      # Login shell = the *wrapped* zsh (config baked in).
      shell = self.packages.${pkgs.system}.zsh;
    };

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      # wrapped packages
      self.packages.${pkgs.system}.nvim
      # (hyprland/kitty/browser are installed by their feature modules)

      # launcher used by Hyprland's SUPER+R keybind
      hyprlauncher

      # user packages
      vesktop
      prismlauncher
      pavucontrol
      steam
      gimp
      krita
      pi-coding-agent # treated as a regular package
      btop
      devenv
      ollama
      ripgrep
      helixnotes-patch
      keepassxc
    ];

    system.stateVersion = "26.05";
  };
}
