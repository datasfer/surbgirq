# {   }:
# with (import <nixpkgs> {});

# haskell.lib.buildStackProject {
#   inherit ghc;
#     name = "surbgirq";
#     buildInputs = ["surbgirq-types" "surbgirq-service" "surbgirq-api" "common" "surbgirq"];

#  }



let ghc      ="ghc883";
    
in
  pkgs.haskell.packages."${ghc}".shellFor {
    nativeBuildInputs = with pkgs.haskellPackages; [
      cabal-install
      ghcid
      stylish-haskell
    ];
    buildInputs = [
      pkgs.pkg-config
    ];
    packages = release."${ghc}";
  }
