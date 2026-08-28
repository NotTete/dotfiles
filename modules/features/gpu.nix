{ self, inputs, ... }: {
  flake.nixosModules.gpu = { config, lib, ... }: {
    # ── Compatibility notes (read before use) ─────────────────────────────────
    # This module assumes a modern NVIDIA GPU that supports the open kernel
    # modules (Turing/Ampere+, i.e. GTX 16xx / RTX 20xx and newer). It sets
    # hardware.nvidia.open = true. On OLDER architectures:
    #
    #   - Maxwell/Pascal (GTX 9xx/10xx): the open driver does NOT work. You must
    #     use the proprietary driver (hardware.nvidia.open = false).
    #   - Kepler and older: not supported at all by modern NVIDIA drivers.
    #
    # CUDA is likewise tied to the GPU generation: old GPUs have lower compute
    # capability (e.g. Pascal = 6.x, Maxwell = 5.x) and may not be supported by
    # the current CUDA toolkit. If compute.enable fails to build or runs with
    # "no kernel image is available", set gpu.compute.capabilities to your GPU's
    # capability and/or check it's new enough for the bundled CUDA version.
    #
    # Laptops with hybrid graphics need real bus IDs from lspci (see below) and
    # PRIME offload requires the iGPU to drive the display.
    options.gpu = {
      mode = lib.mkOption {
        type = lib.types.enum [ "off" "headless" "x11" "wayland" ];
        default = "off";
        description = ''
          GPU / display stack mode:

          - off:      nothing at all, no NVIDIA driver, no graphics.
          - headless: load the NVIDIA driver, but no display stack (server / AI box).
          - x11:      full X11 desktop.
          - wayland:  Wayland desktop (e.g. Hyprland), with XWayland for X11 apps.
        '';
      };

      # ── Hybrid (PRIME) graphics ──────────────────────────────────────────────
      # For laptops with an integrated GPU (Intel/AMD) + an NVIDIA dGPU.
      # To find the bus IDs, on the laptop run:
      #
      #   lspci | grep -E "VGA|3D controller"
      #
      # Example output:
      #   00:02.0 VGA compatible controller: Intel ... UHD Graphics
      #   01:00.0 VGA compatible controller: NVIDIA ... RTX 4060
      #
      # Convert each address by replacing the first "." with ":" and prefixing "PCI:":
      #   00:02.0  ->  PCI:0:2:0    (iGPU)
      #   01:00.0  ->  PCI:1:0:0    (NVIDIA)
      #
      # NVIDIA is usually PCI:1:0:0 and the iGPU PCI:0:2:0, but always confirm
      # with lspci on the actual machine. Use intelBusId or amdgpuBusId depending
      # on which brand the integrated GPU is.
      hybrid.enable = lib.mkEnableOption "hybrid (PRIME) graphics with integrated + discrete GPU";
      hybrid.mode = lib.mkOption {
        type = lib.types.enum [ "offload" "sync" "reverseSync" ];
        default = "offload";
        description = ''
          PRIME mode:

          - offload:      iGPU drives the display, NVIDIA on-demand per-app (best battery).
          - sync:         NVIDIA always on for all rendering.
          - reverseSync:  iGPU renders, NVIDIA drives external outputs.
        '';
      };
      hybrid.nvidiaBusId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          PCI bus ID of the NVIDIA GPU, e.g. "PCI:1:0:0" (get with lspci).
        '';
        example = "PCI:1:0:0";
      };
      hybrid.intelBusId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          PCI bus ID of the Intel iGPU, e.g. "PCI:0:2:0".
        '';
        example = "PCI:0:2:0";
      };
      hybrid.amdgpuBusId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          PCI bus ID of the AMD iGPU, e.g. "PCI:0:2:0".
        '';
        example = "PCI:0:2:0";
      };

      compute.enable = lib.mkEnableOption "CUDA compute support (AI/ML)";
      # NOTE: on older GPUs (Maxwell/Pascal and below), the bundled CUDA toolkit
      # may not support your card. Set compute.capabilities to your GPU's compute
      # capability, and check it's still supported by the current CUDA version.
      # If you get "no kernel image is available for execution on the device",
      # the GPU is likely too old for this nixpkgs' CUDA.
      compute.capabilities = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = ''
          CUDA compute capabilities to build for, e.g. [ "8.9" ] (Ada Lovelace) or [ "9.0" ].
          Empty builds for the full supported range of the CUDA version.
        '';
      };
    };

    config = let
      graphical = lib.elem config.gpu.mode [ "x11" "wayland" ];
      # headless always loads the driver (no GUI); compute layers CUDA on top.
      needNvidia = config.gpu.mode != "off" || config.gpu.compute.enable;
      h = config.gpu.hybrid;
    in
    lib.mkMerge [
      (lib.mkIf graphical {
        hardware.graphics.enable = true;
        hardware.graphics.enable32Bit = true;
      })
      (lib.mkIf (config.gpu.mode == "wayland") {
        # XWayland: lets X11 apps run inside the Wayland session.
        programs.xwayland.enable = true;
      })
      (lib.mkIf (config.gpu.mode == "x11") {
        services.xserver.enable = true;
        # Hybrid: display driven by the iGPU (modesetting), not NVIDIA.
        services.xserver.videoDrivers = if h.enable then [ "modesetting" ] else [ "nvidia" ];
      })
      (lib.mkIf needNvidia {
        hardware.nvidia.open = true;
      })
      (lib.mkIf h.enable {
        hardware.nvidia.prime.nvidiaBusId = h.nvidiaBusId;
        hardware.nvidia.prime.intelBusId = lib.mkIf (h.intelBusId != null) h.intelBusId;
        hardware.nvidia.prime.amdgpuBusId = lib.mkIf (h.amdgpuBusId != null) h.amdgpuBusId;
        # suspend/resume support (any NVIDIA setup)
        hardware.nvidia.powerManagement.enable = true;
      })
      (lib.mkIf (h.enable && h.mode == "offload") {
        hardware.nvidia.prime.offload.enable = true;
        hardware.nvidia.prime.offload.enableOffloadCmd = true;
        # battery: power-down the dGPU when idle (offload only)
        hardware.nvidia.powerManagement.finegrained = true;
      })
      (lib.mkIf (h.enable && h.mode == "sync") {
        hardware.nvidia.prime.sync.enable = true;
      })
      (lib.mkIf (h.enable && h.mode == "reverseSync") {
        hardware.nvidia.prime.reverseSync.enable = true;
      })
      (lib.mkIf config.gpu.compute.enable {
        nixpkgs.config.cudaSupport = true;
        nixpkgs.config.cudaCapabilities = config.gpu.compute.capabilities;
      })
      {
        assertions = [
          {
            assertion = config.gpu.mode != "off" || !config.gpu.compute.enable;
            message = "gpu.compute.enable requires gpu.mode != \"off\" (can't run CUDA with no driver)";
          }
          {
            assertion = !h.enable || graphical;
            message = "gpu.hybrid.enable requires gpu.mode to be x11 or wayland";
          }
          {
            assertion =
              !h.enable
              || (h.nvidiaBusId != null && (h.intelBusId != null || h.amdgpuBusId != null));
            message = "gpu.hybrid.enable requires gpu.hybrid.nvidiaBusId and either intelBusId or amdgpuBusId";
          }
        ];
      }
    ];
  };
}
