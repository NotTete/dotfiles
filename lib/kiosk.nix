# Shared helper that builds a kiosk-mode desktop entry for a web app.
#
# Usage (from a feature module):
#   let
#     mkKiosk = import ../../lib/kiosk.nix { inherit lib pkgs; };
#   in
#     mkKiosk {
#       name = "slskd";
#       desktopName = "slskd";
#       url = "http://miquella:5030";
#       profile = "${config.users.users.tete.home}/.config/slskd-kiosk";
#       icon = "network-server";
#       comment = "Open slskd in kiosk mode";
#     }
#
# Returns a list of packages (the launcher script + a .desktop entry).
{ lib, pkgs }:
{
  name,
  desktopName ? name,
  url,
  profile,
  browser ? pkgs.firefox,
  icon ? "web-browser",
  comment ? "Open ${desktopName} in kiosk mode",
}:
let
  # about:config prefs written to the kiosk profile's user.js. Hardcoded to
  # lock the kiosk down: hide the URL bar, block popups/new windows, disable
  # navigation shortcuts, and suppress password/insecure-connection prompts.
  prefs = {
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

  userJs = pkgs.writeText "${name}-kiosk-user.js" (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (n: v: "user_pref(\"${n}\", ${v});") prefs
    ) + "\n"
  );

  # Hides the entire browser chrome (tab bar, URL bar, menu bar, bookmarks bar)
  # so only the web content is visible, without going fullscreen. Requires
  # toolkit.legacyUserProfileCustomizations.
  userChromeCss = pkgs.writeText "userChrome.css" ''
    #navigator-toolbox { display: none !important; }
  '';

  # Wrapper that creates the profile dir (Firefox's --profile needs it to
  # exist) and seeds user.js before launching, so it works without waiting for
  # tmpfiles at boot. user.js is always overwritten so pref changes take
  # effect, and saved logins are cleared so no previous passwords are shown.
  kioskScript = pkgs.writeShellScriptBin name ''
    PROFILE="${profile}"
    mkdir -p "$PROFILE/chrome"
    # install (not cp) so the copied user.js is writable (cp preserves the
    # read-only nix-store source perms, which blocks later updates).
    install -m 0644 ${userJs} "$PROFILE/user.js"
    install -m 0644 ${userChromeCss} "$PROFILE/chrome/userChrome.css"
    rm -f "$PROFILE/logins.json" "$PROFILE/signons.sqlite"
    exec ${browser}/bin/firefox --new-instance --profile "$PROFILE" ${url}
  '';
in
  [
    kioskScript
    (pkgs.makeDesktopItem {
      inherit name desktopName icon comment;
      exec = "${kioskScript}/bin/${name}";
      categories = [ "Network" "WebBrowser" ];
    })
  ]
