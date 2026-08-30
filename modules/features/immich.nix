{ self, inputs, ... }: {
  flake.nixosModules.immich = { config, lib, pkgs, ... }: {
    options.immich = {
      enableServer = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable the Immich photo service.

          The server listener binds on all interfaces but the firewall only
          accepts traffic coming from the tailscale network (100.64.0.0/10),
          so it is only reachable through the tailnet.
        '';
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 2283;
        description = "Port Immich will listen on (only reachable via tailscale).";
      };

      enableDesktop = lib.mkEnableOption ''
        a desktop entry that opens Immich in kiosk mode (fullscreen browser,
        no chrome). Useful for a photo-frame / kiosk setup.
      '';

      kioskUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://miquella:2283";
        description = "Immich URL to open in kiosk mode (reachable via tailscale).";
      };

      kioskBrowser = lib.mkOption {
        type = lib.types.package;
        default = pkgs.firefox;
        description = "Browser used for kiosk mode.";
      };

      # Dedicated profile so the kiosk instance doesn't clash with a normal
      # Firefox session (two Gecko instances can run side by side). Lives under
      # ~/.config so it's always writable by the user (unlike ~/.mozilla which
      # can end up root-owned).
      kioskProfile = lib.mkOption {
        type = lib.types.path;
        default = "${config.users.users.tete.home}/.config/immich-kiosk";
        description = "Absolute path to the Firefox profile used for the kiosk instance.";
      };

      # Extra about:config prefs written to the kiosk profile's user.js.
      # Defaults lock the kiosk down: hide the URL bar, block popups/new
      # windows, and disable navigation shortcuts so the user can't leave the
      # Immich URL.
      kioskPrefs = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          "browser.urlbar.hidden" = "true";
          "browser.tabs.allowTabDetach" = "false";
          "browser.ctrlTab.recentlyUsedOrder" = "false";
          "browser.allowpopups" = "false";
          "dom.disable_open_during_load" = "true";
          "browser.shell.checkDefaultBrowser" = "false";
          "browser.tabs.warnOnClose" = "false";
          "browser.tabs.warnOnOpen" = "false";
          "browser.sessionstore.resume_from_crash" = "false";
          "browser.uidensity" = "1";

          # No password saving / form autofill prompts.
          "signon.rememberSignons" = "false";
          "signon.autofillForms" = "false";
          "signon.rememberSignons.visibilityToggle" = "false";
          "browser.formfill.enable" = "false";

          # Don't show the "Connection is not secure" / padlock indicator.
          "security.identityblock.show_extended_validation" = "false";
          "security.ssl.enable_ocsp_stapling" = "false";

          # No first-run welcome page / Firefox logo on the new-tab page.
          "browser.aboutwelcome.enabled" = "false";
          "browser.startup.page" = "0";
          "browser.newtabpage.enabled" = "false";
          "browser.newtabpage.activity-stream.feeds.topsites" = "false";
          "browser.newtabpage.activity-stream.feeds.section.topstories" = "false";

          # Allow userChrome.css (used to hide the whole browser UI).
          "toolkit.legacyUserProfileCustomizations.stylesheets" = "true";

          # Don't warn about typing a password on an insecure (HTTP) page.
          "security.insecure_password.ui.enabled" = "false";
        };
        description = "about:config preferences to write into the kiosk profile's user.js.";
      };
    };

    config = lib.mkMerge [
      (lib.mkIf config.immich.enableServer {
        services.immich = {
          enable = true;
          host = "0.0.0.0";
          openFirewall = false;
          machine-learning.environment = {
            MACHINE_LEARNING_MODEL_TTL = "60";
            MACHINE_LEARNING_CONCURRENCY = "1";
          };
        };

        networking.firewall.extraInputRules = ''
          ip saddr 100.64.0.0/10 tcp dport ${toString config.immich.port} accept
        '';
      })

      (lib.mkIf config.immich.enableDesktop (let
          userJs = pkgs.writeText "immich-kiosk-user.js" (
            lib.concatStringsSep "\n" (
              lib.mapAttrsToList (name: value: "user_pref(\"${name}\", ${value});") config.immich.kioskPrefs
            ) + "\n"
          );

          # Hides the entire browser chrome (tab bar, URL bar, menu bar,
          # bookmarks bar) so only the web content is visible, without going
          # fullscreen. Requires toolkit.legacyUserProfileCustomizations.
          userChromeCss = pkgs.writeText "userChrome.css" ''
            #navigator-toolbox { display: none !important; }
          '';

          # Wrapper that creates the profile dir (Firefox's --profile needs it
          # to exist) and seeds user.js before launching, so it works without
          # waiting for tmpfiles at boot. user.js is always overwritten so pref
          # changes take effect, and saved logins are cleared so no previous
          # passwords are shown.
          kioskScript = pkgs.writeShellScriptBin "immich" ''
            PROFILE="${config.immich.kioskProfile}"
            mkdir -p "$PROFILE/chrome"
            # install (not cp) so the copied user.js is writable (cp preserves
            # the read-only nix-store source perms, which blocks later updates).
            install -m 0644 ${userJs} "$PROFILE/user.js"
            install -m 0644 ${userChromeCss} "$PROFILE/chrome/userChrome.css"
            rm -f "$PROFILE/logins.json" "$PROFILE/signons.sqlite"
            exec ${config.immich.kioskBrowser}/bin/firefox --new-instance --profile "$PROFILE" ${config.immich.kioskUrl}
          '';
        in {
          environment.systemPackages = [
            kioskScript
            (pkgs.makeDesktopItem {
              name = "immich";
              desktopName = "Immich";
              exec = "${kioskScript}/bin/immich";
              icon = "camera-photo";
              comment = "Open Immich in kiosk mode";
              categories = [ "Network" "WebBrowser" ];
            })
          ];
        }))
    ];
  };
}
