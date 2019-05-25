{ ghc }:
with (import <nixpkgs> {});

haskell.lib.buildStackProject {
  inherit ghc;
    name = "surbgirq";
    buildInputs = ["surbgirq-types" "surbgirq-service" "surbgirq-api" "common" "surbgirq"];

 }
