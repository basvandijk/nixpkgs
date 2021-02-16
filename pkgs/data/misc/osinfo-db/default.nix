{ lib, stdenv, fetchurl, osinfo-db-tools, gettext, libxml2 }:

stdenv.mkDerivation rec {
  pname = "osinfo-db";
  version = "20210202";

  src = fetchurl {
    url = "https://releases.pagure.org/libosinfo/${pname}-${version}.tar.xz";
    sha256 = "sha256-C7Vq7d+Uos9IhTwOgsrK64c9mMGVkNgfvOrbBqORsRs=";
  };

  nativeBuildInputs = [ osinfo-db-tools gettext libxml2 ];

  phases = [ "installPhase" ];

  installPhase = ''
    osinfo-db-import --dir "$out/share/osinfo" "${src}"
  '';

  meta = with lib; {
    description = "Osinfo database of information about operating systems for virtualization provisioning tools";
    homepage = "https://gitlab.com/libosinfo/osinfo-db/";
    license = licenses.gpl2Plus;
    platforms = platforms.unix;
    maintainers = [ maintainers.bjornfor ];
  };
}
