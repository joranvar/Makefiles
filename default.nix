{ stdenv, haskellPackages }:

let
  env = haskellPackages.ghcWithPackages (p: with p; [
    #{dev-deps}
    happy
    # ghc-mod
    hlint
    hoogle
    structured-haskell-mode
    hasktags
    present
    stylish-haskell

    #{deps}
  ]);
in
  stdenv.mkDerivation {
    name        = "#{name}";
    buildInputs = [env];
    shellHook   = ''
      export NIX_GHC="${env}/bin/ghc"
      export NIX_GHCPKG="${env}/bin/ghc-pkg"
      export NIX_GHC_DOCDIR="${env}/share/doc/ghc/html"
      export NIX_GHC_LIBDIR=$( $NIX_GHC --print-libdir )
    '';
  }
