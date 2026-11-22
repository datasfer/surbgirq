{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    # System dependencies
    pkgs.zlib
    pkgs.sqlite
    pkgs.pkg-config
    pkgs.openssl
    pkgs.git
    pkgs.curl
    pkgs.ncurses

    # Haskell dev tools
    pkgs.haskellPackages.ghcid
    pkgs.haskellPackages.stylish-haskell
    pkgs.haskellPackages.hlint
    pkgs.haskellPackages.haskell-language-server-wrapper-2.10.0.0
  ];

  shellHook = ''
    export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.zlib.dev}/lib/pkgconfig"
    echo "🟢 Dev shell with ghcid and stylish-haskell ready"
  '';
}