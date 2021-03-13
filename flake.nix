{
  description = "A very basic flake";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShell = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          (zig.overrideAttrs (old: {
            version = "git";
            src = fetchFromGitHub {
              owner = "ziglang";
              repo = "zig";
              rev = "0447a2c041a4be843251396e668e074186aa49a2";
              sha256 = "+FIMlrGqlj2K6HZk9+QiT0oFsfqaTRCF2XTrfu+Yskg=";
            };
          }))
          avrdude
          pkgsCross.avr.buildPackages.binutils
          pkgsCross.avr.buildPackages.gdb
          (callPackage ./simulavr.nix {})
        ];
      };
    });
}
