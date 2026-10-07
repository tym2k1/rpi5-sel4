{ pkgs, seL4Test-manifest }:

let
  crossPkgs = pkgs.pkgsCross.aarch64-multiplatform;
  seL4Test = pkgs.stdenv.mkDerivation {
    pname = "seL4Test";
    version = "04-10-2024";

    src = seL4Test-manifest;
    nativeBuildInputs = with pkgs; [
      cmake
      ninja
      git
      dtc
      libxml2Python
      protobuf

      (python3.withPackages (ps: [
        ps.pyyaml
        ps.pyfdt
        ps.jinja2
        ps.ply
        ps.typing-extensions
        ps.lxml
        ps.protobuf
        ps.libarchive-c
        ps.pyelftools
      ]))

      crossPkgs.stdenv.cc
    ];

    NIX_CFLAGS_COMPILE = "-fno-stack-protector";

    dontConfigure = true;

    buildPhase = ''
      mkdir -p $out
      echo $out
      export HOME="$out/.home"
      mkdir -p "$HOME"
      echo "HOME=$HOME"
    '';

    installPhase = ''
      # TODO
    '';
  };

seL4Test-shell = pkgs.mkShell {
  packages = seL4Test.nativeBuildInputs;

  shellHook = ''
    # init-build.sh assumes HOME exists.
    # To silence it
    if [ -z "''${HOME:-}" ]; then
          export HOME="$PWD/.home"
    fi

    mkdir -p "$HOME"

    echo "seL4Test development shell"
    echo "HOME=$HOME"
    echo "cmake=$(command -v cmake)"
    echo "ninja=$(command -v ninja)"
  '';
  };
in
{
  inherit
    seL4Test
    seL4Test-shell;
}
