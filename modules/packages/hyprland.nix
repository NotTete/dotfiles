{ self, inputs, lib, ... }:
let
  mkHyprland = pkgs: inputs.wrappers.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.hyprland;
    # XWayland must be on PATH so Hyprland can spawn it and set $DISPLAY for
    # X11 apps (e.g. Minecraft via Prism Launcher).
    runtimeInputs = with pkgs; [ xwayland ];
    # Patch the Wayland session entry too so ly launches the *wrapped* binary,
    # not the original one baked into the desktop file.
    filesToPatch = [
      "nix-support/*"
      "share/applications/*.desktop"
      "share/wayland-sessions/*.desktop"
    ];
    flags."--config" = pkgs.writeText "hyprland.lua" ''
      local mod = "SUPER"

      -- --- Monitors ---
      hl.monitor({
        output   = "",
        mode     = "preferred",
        position = "auto",
        scale    = "auto",
      })

      -- --- General / layout ---
      hl.config({
        general = {
          gaps_in     = 5,
          gaps_out    = 10,
          border_size = 2,
          layout      = "dwindle",
        },
        dwindle = {
          preserve_split       = true,
          special_scale_factor = 0.95,
        },
      })

      -- --- Input ---
      hl.config({
        input = {
          kb_layout   = "es",
          follow_mouse = 1,
          sensitivity = 0,
          touchpad = {
            natural_scroll = true,
          },
        },
      })

      hl.device({
        name        = "epic-mouse-v1",
        sensitivity = -0.5,
      })

      -- --- Misc ---
      hl.config({
        cursor = {
          -- NVIDIA Wayland: hardware cursors cause the cursor to blink/flicker
          -- when moving. Force software cursors instead.
          no_hardware_cursors = true,
        },
        misc = {
          force_default_wallpaper = 0,
          disable_hyprland_logo   = true,
        },
      })


      -- --- Keybindings ---
      hl.bind(mod .. " + T", hl.dsp.exec_cmd("kitty"))
      hl.bind(mod .. " + R", hl.dsp.exec_cmd("hyprlauncher"))
      hl.bind(mod .. " + Q", hl.dsp.window.close())
      hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))

      hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
      hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
      hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))
      hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))

      hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
      hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

      for i = 1, 10 do
        local key = tostring(i == 10 and 0 or i)
        hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
        hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
      end
    '';
  };
in {
  perSystem = { pkgs, ... }: {
    packages.hyprland = mkHyprland pkgs;
  };
}
