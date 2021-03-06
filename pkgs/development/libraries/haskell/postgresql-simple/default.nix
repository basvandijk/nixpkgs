# This file was auto-generated by cabal2nix. Please do NOT edit manually!

{ cabal, aeson, attoparsec, base16Bytestring, blazeBuilder
, blazeTextual, caseInsensitive, cryptohash, hashable, HUnit
, postgresqlLibpq, scientific, text, time, transformers, uuid
, vector
}:

cabal.mkDerivation (self: {
  pname = "postgresql-simple";
  version = "0.4.8.0";
  sha256 = "09mflczxjm7a8nixi4a989nq1ijhpikl4j9kqvzcpmfgb8sx38nm";
  buildDepends = [
    aeson attoparsec blazeBuilder blazeTextual caseInsensitive hashable
    postgresqlLibpq scientific text time transformers uuid vector
  ];
  testDepends = [
    aeson base16Bytestring cryptohash HUnit text time vector
  ];
  doCheck = false;
  meta = {
    description = "Mid-Level PostgreSQL client library";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
