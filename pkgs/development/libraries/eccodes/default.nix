{ fetchurl, stdenv
, cmake, netcdf, openjpeg, libpng, gfortran
, enablePython ? false, pythonPackages
, enablePosixThreads ? false
, enableOpenMPThreads ? false}:
with stdenv.lib; 
stdenv.mkDerivation rec {
  name = "eccodes-${version}";
  version = "2.9.0";

  src = fetchurl {
    url = "https://confluence.ecmwf.int/download/attachments/45757960/eccodes-${version}-Source.tar.gz";
    sha256 = "1mh9zkfb5dj3j8fk3gdhz2bp6z13nik5pmynpf5l6qy3lhgyn17z";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [ netcdf
                  openjpeg
                  libpng
                  gfortran
                ];
  propagatedBuildInputs = optionals enablePython [
                  pythonPackages.python
                  pythonPackages.numpy
                ];

  cmakeFlags = [ "-DENABLE_PYTHON=${if enablePython then "ON" else "OFF"}"
                 "-DENABLE_PNG=ON"
                 "-DENABLE_ECCODES_THREADS=${if enablePosixThreads then "ON" else "OFF"}"
                 "-DENABLE_ECCODES_OMP_THREADS=${if enableOpenMPThreads then "ON" else "OFF"}"
               ];

  enableParallelBuilding = true;

  doCheck = true;

  # Only do tests that don't require downloading 120MB of testdata
  checkPhase = stdenv.lib.optionalString (stdenv.isDarwin) ''
    substituteInPlace "tests/include.sh" --replace "set -ea" "set -ea; export DYLD_LIBRARY_PATH=$(pwd)/lib"
  '' + ''
    ctest -R "eccodes_t_(definitions|calendar|unit_tests|md5|uerra|grib_2nd_order_numValues|julian)" -VV
  '';

  meta = {
    homepage = https://confluence.ecmwf.int/display/ECC/;
    license = licenses.asl20;
    maintainers = with maintainers; [ knedlsepp ];
    platforms = platforms.unix;
    description = "ECMWF library for reading and writing GRIB, BUFR and GTS abbreviated header";
  };
}
