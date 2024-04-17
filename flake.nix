{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        bazel = pkgs.bazel_5;
        nativeBuildInputs = with pkgs; [
          git
          installShellFiles
          python3
          libtool
        ];
      in 
      {
        packages = {
          default = pkgs.buildBazelPackage {
            inherit bazel;
            inherit nativeBuildInputs;
            pname = "bazel-test-b";
            version = "HEAD";
            src = ./.;
            # do not use Xcode on macOS
            BAZEL_USE_CPP_ONLY_TOOLCHAIN = "1";
            # for nixpkgs cc wrappers, select C++ explicitly (see https://github.com/NixOS/nixpkgs/issues/150655)
            BAZEL_CXXOPTS = "-x:c++";
            removeRulesCC = false;
            bazelTargets = [ "//src:test-b" ];
            fetchAttrs = {
              sha256 = "sha256-0mwYtVTn55ahR9sEfSnfSXLFc/wKggwt3Ji2vfyJyHd=";
            };
            buildAttrs = {
              preBuild = ''
                mv .bazelrc.nix-build .bazelrc
              '';
              installPhase = ''
                install -Dm755 bazel-bin/src/hello-world $out/bin/hello-world
              '';
            };
          };
        };

        devShells.default =
          pkgs.mkShellNoCC {
            name = "rules_nixpkgs_shell";
            packages = with pkgs; [ bazel bazel-buildtools cacert nix git ];
          };
      });
}
