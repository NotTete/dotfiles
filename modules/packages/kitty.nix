{ self, inputs, lib, ... }:
let
  toKeybindings = lib.generators.toKeyValue {
    mkKeyValue = key: command: "map ${key} ${command}";
  };

  mkKitty = pkgs: (inputs.wrappers.wrapperModules.kitty.apply {
    inherit pkgs;

    settings = {
      font_size = 13;
      font_family = "JetBrainsMono Nerd Font";
      background_opacity = 0.9;

      scrollbar = "never";
      cursor_trail = "1";
      confirm_os_window_close = 0;

      tab_bar_style = "fade";
      tab_bar_edge = "top";
      tab_bar_min_tabs = 1;
      tab_bar_margin_height = "5 0";
      tab_bar_margin_width = 5;

      enabled_layouts = "splits:split_axis=vertical";
    };

    extraSettings = toKeybindings {
      "ctrl+space>ctrl+left" = "detach_window tab-left";
      "ctrl+space>ctrl+right" = "detach_window tab-right";
      "ctrl+space>ctrl+d" = "detach_window new-tab";

      "alt+shift+left" = "move_tab_backward";
      "alt+shift+right" = "move_tab_forward";

      "ctrl+space>up" = "move_window up";
      "ctrl+space>left" = "move_window left";
      "ctrl+space>right" = "move_window right";
      "ctrl+space>down" = "move_window down";

      "ctrl+shift+left" = "resize_window narrower";
      "ctrl+shift+right" = "resize_window wider";
      "ctrl+shift+up" = "resize_window taller";
      "ctrl+shift+down" = "resize_window shorter";

      "alt+left" = "neighboring_window left";
      "alt+right" = "neighboring_window right";
      "alt+up" = "neighboring_window up";
      "alt+down" = "neighboring_window down";

      "ctrl+space>v" = "launch --location=vsplit --cwd=current";
      "ctrl+space>b" = "launch --location=hsplit --cwd=current";
      "ctrl+space>n" = "launch --type=tab --cwd=current";

      "alt+q" = "close_window";
      "alt+shift+q" = "close_tab";

      "alt+1" = "goto_tab 1";
      "alt+2" = "goto_tab 2";
      "alt+3" = "goto_tab 3";
      "alt+4" = "goto_tab 4";
      "alt+5" = "goto_tab 5";
      "alt+6" = "goto_tab 6";
      "alt+7" = "goto_tab 7";
      "alt+8" = "goto_tab 8";
      "alt+9" = "goto_tab 9";
      "alt+0" = "goto_tab 10";
    };
  }).wrapper;
in {
  perSystem = { pkgs, ... }: {
    packages.kitty = mkKitty pkgs;
  };
}
