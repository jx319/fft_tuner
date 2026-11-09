{
  description = "A Flutter project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config = {
          android_sdk.accept_license = true;
          allowUnfree = true;
        };
      };
      androidsdk_composed =
        (pkgs.androidenv.composeAndroidPackages {
          platformVersions = [
            "35"
            "36"
          ];
          systemImageTypes = [ ];
          abiVersions = [
            "arm64-v8a"
          ];
          includeNDK = true;
          ndkVersion = "28.2.13676358";
          cmakeVersions = [ "3.22.1" ];
          buildToolsVersions = [ "35.0.0" "36.0.0" ];
          toolsVersion = null;
          includeExtras = [ ];
        }).androidsdk;
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        ANDROID_HOME = "${androidsdk_composed}/libexec/android-sdk";
        CHROME_EXECUTABLE = nixpkgs.lib.getExe pkgs.ungoogled-chromium;
        buildInputs = with pkgs; [
          flutter
          jdk21
          androidsdk_composed
        ];
      };
    };
}
