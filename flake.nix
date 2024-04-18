{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        bazel = pkgs.bazel_6;
        buildInputs = pkgs.lib.optional pkgs.stdenv.isDarwin pkgs.darwin.cctools;
        nativeBuildInputs = with pkgs; [
          git
          installShellFiles
          python3
        ];
      in 
      {
        packages = {
          default = pkgs.buildBazelPackage {
            inherit bazel;
            inherit buildInputs;
            inherit nativeBuildInputs;
            pname = "bazel-test-b";
            version = "HEAD";
            src = ./.;
            # do not use Xcode on macOS
            BAZEL_USE_CPP_ONLY_TOOLCHAIN = "1";
            # for nixpkgs cc wrappers, select C++ explicitly (see https://github.com/NixOS/nixpkgs/issues/150655)
            BAZEL_CXXOPTS = "-x:c++";
            dontAddBazelOpts = true;
            bazelTargets = [ "//:test-b" ];
            fetchAttrs = {
              sha256 = "sha256-earE4hno0r+AmY3vFUpWoO5wmR+/C/wYO/Amycgcw+Q=";
            };
            buildAttrs = {
              preBuild = ''
                mv .bazelrc.nix-build .bazelrc
              '';
              # TODO(jnewman): figure out what to copy.. .a files? .dylib files? surely nix has a helper?
              installPhase = ''
                mkdir $out
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
