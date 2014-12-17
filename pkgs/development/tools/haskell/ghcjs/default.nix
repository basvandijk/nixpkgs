{ nodejs, cabal, filepath, HTTP, HUnit, mtl, network, QuickCheck, random, stm
, testFramework, testFrameworkHunit, testFrameworkQuickcheck2, time
, zlib, aeson, attoparsec, bzlib, dataDefault, ghcPaths, hashable
, haskellSrcExts, haskellSrcMeta, lens, optparseApplicative_0_11_0_1
, parallel, safe, shelly, split, stringsearch, syb, systemFileio
, systemFilepath, tar, terminfo, textBinary, unorderedContainers
, vector, wlPprintText, yaml, fetchgit, Cabal, CabalGhcjs, cabalInstall
, regexPosix, alex, happy, git, gnumake, gcc, autoconf, patch
, automake, libtool, cabalInstallGhcjs, gmp, base16Bytestring
, cryptohash, executablePath, transformersCompat, haddockApi
, haddock, hspec, xhtml, primitive, cacert, pkgs, ghc
, coreutils
}:
let
  version = "0.1.0";
  libDir = "share/ghcjs/${pkgs.stdenv.system}-${version}-${ghc.ghc.version}/ghcjs";
  ghcjsBoot = fetchgit {
    url = git://github.com/ghcjs/ghcjs-boot.git;
    rev = "67c73ea50b4b2ba174855534bf7a9b5088d86e0d";
    sha256 = "1f6695f7c25e40b87621ba6ce71a8338788951fd85e88e9223c8258520fbded6";
  };
  shims = fetchgit {
    url = git://github.com/ghcjs/shims.git;
    rev = "5e11d33cb74f8522efca0ace8365c0dc994b10f6";
    sha256 = "64be139022e6f662086103fca3838330006d38e6454bd3f7b66013031a47278e";
  };
  ghcjsPrim = cabal.mkDerivation (self: {
    pname = "ghcjs-prim";
    version = "0.1.0.0";
    src = fetchgit {
      url = git://github.com/ghcjs/ghcjs-prim.git;
      rev = "8e003e1a1df10233bc3f03d7bbd7d37de13d2a84";
      sha256 = "ff1a69a38b575d2368dbcfb750d9317dd44d2c8c34183b7dbf95a3a20fca6286";
    };
    buildDepends = [ primitive ];
  });
in cabal.mkDerivation (self: rec {
  pname = "ghcjs";
  inherit version;
  src = fetchgit {
    url = git://github.com/ghcjs/ghcjs.git;
    rev = "5ea2d2783dfecd6a3d8b13c9568510f8ab48a5de";
    sha256 = "8eaa036cb51996d3144c43581cd3b195c28cfdbb4831d444e6d6f19499301f27";
  };
  isLibrary = true;
  isExecutable = true;
  jailbreak = true;
  noHaddock = true;
  doCheck = false;
  buildDepends = [
    filepath HTTP mtl network random stm time zlib aeson attoparsec
    bzlib dataDefault ghcPaths hashable haskellSrcExts haskellSrcMeta
    lens optparseApplicative_0_11_0_1 parallel safe shelly split
    stringsearch syb systemFileio systemFilepath tar terminfo textBinary
    unorderedContainers vector wlPprintText yaml
    alex happy git gnumake gcc autoconf automake libtool patch gmp
    base16Bytestring cryptohash executablePath haddockApi
    transformersCompat QuickCheck haddock hspec xhtml
    ghcjsPrim regexPosix
  ];
  buildTools = [ nodejs git ];
  testDepends = [
    HUnit testFramework testFrameworkHunit
  ];
  patches = [ ./ghcjs.patch ];
  postPatch = ''
    substituteInPlace Setup.hs --replace "/usr/bin/env" "${coreutils}/bin/env"
    substituteInPlace src/Compiler/Info.hs --replace "@PREFIX@" "$out"
    substituteInPlace src-bin/Boot.hs --replace "@PREFIX@" "$out"
  '';
  postInstall = ''
    local topDir=$out/${libDir}
    mkdir -p $topDir

    cp -r ${ghcjsBoot} $topDir/ghcjs-boot
    chmod -R u+w $topDir/ghcjs-boot

    cp -r ${shims} $topDir/shims
    chmod -R u+w $topDir/shims

    PATH=$out/bin:${CabalGhcjs}/bin:$PATH LD_LIBRARY_PATH=${gmp}/lib:${gcc.gcc}/lib64:$LD_LIBRARY_PATH \
      env -u GHC_PACKAGE_PATH $out/bin/ghcjs-boot \
        --dev \
        --with-cabal ${cabalInstallGhcjs}/bin/cabal-js \
        --with-gmp-includes ${gmp}/include \
        --with-gmp-libraries ${gmp}/lib
  '';
  passthru = {
    inherit libDir;
  };
  meta = {
    homepage = "https://github.com/ghcjs/ghcjs";
    description = "GHCJS is a Haskell to JavaScript compiler that uses the GHC API";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
    maintainers = [ self.stdenv.lib.maintainers.jwiegley ];
  };
})
