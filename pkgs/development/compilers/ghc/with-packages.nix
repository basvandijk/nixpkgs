{ stdenv, ghc, packages, buildEnv, makeWrapper, ignoreCollisions ? false }:

let isGhcJs = ghc ? pname && ghc.pname == "ghcjs"; in

# This wrapper works only with GHC > 6.12 or with GHCJS.
assert stdenv.lib.versionOlder "6.12" ghc.version || isGhcJs;

# It's probably a good idea to include the library "ghc-paths" in the
# compiler environment, because we have a specially patched version of
# that package in Nix that honors these environment variables
#
#   NIX_GHC
#   NIX_GHCPKG
#   NIX_GHC_DOCDIR
#   NIX_GHC_LIBDIR
#
# instead of hard-coding the paths. The wrapper sets these variables
# appropriately to configure ghc-paths to point back to the wrapper
# instead of to the pristine GHC package, which doesn't know any of the
# additional libraries.
#
# A good way to import the environment set by the wrapper below into
# your shell is to add the following snippet to your ~/.bashrc:
#
#   if [ -e ~/.nix-profile/bin/ghc ]; then
#     eval $(grep export ~/.nix-profile/bin/ghc)
#   fi

let
  packageDBFlag = if stdenv.lib.versionOlder "7.6.1" ghc.version || isGhcJs
                  then "--global-package-db"
                  else "--global-conf";
  isHaskellPkg  = x: (x ? pname) && (x ? version);
in
if packages == [] then ghc else
buildEnv {
  name = "haskell-env-${ghc.name}";
  paths = stdenv.lib.filter isHaskellPkg (stdenv.lib.closePropagation packages) ++ [ghc];
  inherit ignoreCollisions;
  postBuild =
    if isGhcJs then
      let libDir        = "$out/lib/ghc-${ghc.nativeGhcVersion}";
          docDir        = "$out/share/doc/ghc-${ghc.version}/html}";
          packageCfgDir = "${libDir}/package.conf.d";
      in ''
        . ${makeWrapper}/nix-support/setup-hook

        for prg in ghcjs \
                   ghcjs-${ghc.version}-${ghc.nativeGhcVersion} \
                   ghcjs-${ghc.version}-${ghc.nativeGhcVersion}.bin; do
          rm -f $out/bin/$prg
          makeWrapper ${ghc}/bin/$prg $out/bin/$prg         \
            --add-flags '"-B$NIX_GHC_LIBDIR"'               \
            --set "NIX_GHC"        "$out/bin/ghcjs"         \
            --set "NIX_GHCPKG"     "$out/bin/ghcjs-pkg"     \
            --set "NIX_GHC_DOCDIR" "${docDir}" \
            --set "NIX_GHC_LIBDIR" "${libDir}"
        done

        for prg in ghcjs-pkg \
                   ghcjs-pkg-${ghc.version}-${ghc.nativeGhcVersion} \
                   ghcjs-pkg-${ghc.version}-${ghc.nativeGhcVersion}.bin; do
          rm -f $out/bin/$prg
          makeWrapper ${ghc}/bin/$prg $out/bin/$prg --add-flags "${packageDBFlag}=${packageCfgDir}"
        done

        $out/bin/ghcjs-pkg recache
    ''
    else
      let libDir        = "$out/lib/ghc-${ghc.version}";
          docDir        = "$out/share/doc/ghc/html";
          packageCfgDir = "${libDir}/package.conf.d";
      in ''
        . ${makeWrapper}/nix-support/setup-hook

        for prg in ghc ghci ghc-${ghc.version} ghci-${ghc.version}; do
          rm -f $out/bin/$prg
          makeWrapper ${ghc}/bin/$prg $out/bin/$prg         \
            --add-flags '"-B$NIX_GHC_LIBDIR"'               \
            --set "NIX_GHC"        "$out/bin/ghc"           \
            --set "NIX_GHCPKG"     "$out/bin/ghc-pkg"       \
            --set "NIX_GHC_DOCDIR" "${docDir}"              \
            --set "NIX_GHC_LIBDIR" "${libDir}"
        done

        for prg in runghc runhaskell; do
          rm -f $out/bin/$prg
          makeWrapper ${ghc}/bin/$prg $out/bin/$prg         \
            --add-flags "-f $out/bin/ghc"                   \
            --set "NIX_GHC"        "$out/bin/ghc"           \
            --set "NIX_GHCPKG"     "$out/bin/ghc-pkg"       \
            --set "NIX_GHC_DOCDIR" "${docDir}"              \
            --set "NIX_GHC_LIBDIR" "${libDir}"
        done

        for prg in ghc-pkg ghc-pkg-${ghc.version}; do
          rm -f $out/bin/$prg
          makeWrapper ${ghc}/bin/$prg $out/bin/$prg --add-flags "${packageDBFlag}=${packageCfgDir}"
        done

        $out/bin/ghc-pkg recache
    '';
}
