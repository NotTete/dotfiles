{ self, inputs, ... }: {
  # Replicates the old home-manager `home.pointerCursor` block (see ../dotfiles
  # home/tete.nix) at the NixOS level, since this flake has no home-manager.
  #
  # home.pointerCursor set the Adwaita cursor theme for GTK (gtk.enable) and
  # X11 (x11.enable) apps and installed the theme package. Just setting
  # XCURSOR_THEME in Hyprland (as before) left GTK/X11 apps with the wrong
  # cursor, so this module wires the theme up everywhere.
  flake.nixosModules.cursor = { pkgs, lib, ... }: {
    # The theme package itself (provides the Adwaita cursor).
    environment.systemPackages = [ pkgs.adwaita-icon-theme ];

    # Make the theme/size visible to every session, not just Hyprland.
    environment.sessionVariables = {
      XCURSOR_THEME = "Adwaita";
      XCURSOR_SIZE = "24";
      HYPRCURSOR_THEME = "Adwaita";
      HYPRCURSOR_SIZE = "24";
    };

    # GTK apps (Firefox, GIMP, Krita, ...) read the cursor theme from dconf.
    programs.dconf.enable = true;
    programs.dconf.profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            cursor-theme = "Adwaita";
            cursor-size = lib.gvariant.mkInt32 24;
          };
        };
      }
    ];
  };
}
