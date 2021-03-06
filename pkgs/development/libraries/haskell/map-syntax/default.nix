# This file was auto-generated by cabal2nix. Please do NOT edit manually!

{ cabal, deepseq, HUnit, mtl, QuickCheck, testFramework
, testFrameworkHunit, testFrameworkQuickcheck2, transformers
}:

cabal.mkDerivation (self: {
  pname = "map-syntax";
  version = "0.2";
  sha256 = "02v1dvq86qzbfbwbza4myj3a6a6a5p059fi5m3g548hmqk3v2p1r";
  buildDepends = [ mtl ];
  testDepends = [
    deepseq HUnit mtl QuickCheck testFramework testFrameworkHunit
    testFrameworkQuickcheck2 transformers
  ];
  meta = {
    description = "Syntax sugar for defining maps";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
