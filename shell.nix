# {   }:
# with (import <nixpkgs> {});

# haskell.lib.buildStackProject {
#   inherit ghc;
#     name = "surbgirq";
#     buildInputs = ["surbgirq-types" "surbgirq-service" "surbgirq-api" "common" "surbgirq"];

#  }


# { pkgs ? import <nixpkgs> {} }:
# let
#   ghc = pkgs.haskell.packages.ghc884.ghcWithPackages (p: with p; [ ghci-pretty ]);
# in
# pkgs.mkShell {
#   buildInputs = [ ghc ];
# }

{ pkgs ? import <nixpkgs> {} }:
let
    ghc  = "ghc884";
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


# { a ? import <nixpkgs> {} }:
# let
# inherit (a) haskellPackages;
# c = a.haskellPackages.ghcWithPackages (b: with b;   [   shh   shh-extras
# # pipes   Glob   hoogle
# ghci-pretty   ]);
# in a.mkShell {   buildInputs = [ c ]; }


# let
#   nixpkgs = import ./nixpkgs.nix {};

# #  inherit (nixpkgs) pkgs;

#   haskell = import ./haskell { inherit pkgs; };

# in
# pkgs.mkShell {
#   buildInputs = with pkgs; [
#     haskell.cabal-install
#     haskell.ghc
#     haskell.ghcide
#     haskell.hlint
#     # Other dependencies such as postgresql-12_x would go here.
#   ];

#   # Use the libraries from the derivation created by ghcWithHoogle.
#   NIX_GHC_LIBDIR = "${haskell.ghc}/lib/ghc-${haskell.ghc.version}";
# }
