{ stdenv
, fetchzip
, cmake
, python3
, help2man
, texinfo
, gzip
}:

stdenv.mkDerivation rec {
  pname = "simulavr";
  version = "1.1.0";

  src = fetchzip {
    url = "https://git.savannah.nongnu.org/cgit/simulavr.git/snapshot/simulavr-release-${version}.tar.gz";
    sha256 = "bvH5I13mhAVavfOBgNPcaAiPfTExejtPdHoI4rwoZYQ=";
  };

  prePatch = ''
    mkdir -p build/doc
    touch build/doc/simulavr.1.gz
    touch build/doc/simulavr.info.gz
    touch build/doc/changelog.gz
  '';

  buildInputs = [
    python3
  ];

  nativeBuildInputs = [
    cmake
    help2man
    texinfo
    gzip
  ];
}
