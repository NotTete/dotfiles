{ self, inputs, lib, ... }:
{
  perSystem = { pkgs, ... }:
  let
    dynacat = pkgs.buildGoModule {
      pname = "dynacat";
      version = "2.4.0";

      src = pkgs.fetchFromGitHub {
        owner = "Panonim";
        repo = "dynacat";
        rev = "2.4.0";
        hash = "sha256-3Bqr0XsJjXUT+7Ln0T75efUNr2SHxaSCtGbxcJn0P5U=";
      };

      vendorHash = "sha256-3aPmZ2lg+h3iO66wqq58fqSjYXXRCIfTk3ghiPLX9Ek=";

      ldflags = [
        "-s"
        "-w"
        "-X github.com/Panonim/dynacat/internal/dynacat.buildVersion=v2.4.0"
      ];

      nativeInstallCheckInputs = [ pkgs.versionCheckHook ];
      doInstallCheck = true;

      meta = with pkgs.lib; {
        description = "A dashboard focused on dynamic reloading and easy integration with external applications.";
        mainProgram = "dynacat";
        homepage = "https://dynacat.artur.zone";
        changelog = "https://github.com/Panonim/dynacat/releases";
        license = licenses.agpl3Only;
        maintainers = [ ];
      };
    };
  in
  {
    packages.dynacat = dynacat;
  };
}
