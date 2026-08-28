{
  description = "A very basic flake";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";

    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    wrappers.url = "github:Lassulus/wrappers";
    nixvim.url = "github:nix-community/nixvim";
    helixnotes.url = "gitlab:ArkHost/HelixNotes";
    sops-nix.url = "github:Mic92/sops-nix";

  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" ];
    imports = [
      (inputs.import-tree ./modules)
    ];
  };
}
