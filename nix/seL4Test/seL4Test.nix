{ pkgs, }:

let
  crossPkgs = pkgs.pkgsCross.aarch64-multiplatform;

  # The revisions below come directly from default.xml of https://github.com/seL4/sel4test-manifest
  # Using fetchgit instead of repo/git-repo means the dependency graph is
  # completely explicit to Nix and all source trees are content-addressed.
  # I really dislike working with git-repo

  musllibc = pkgs.fetchgit {
    url = "https://github.com/seL4/musllibc.git";
    rev = "b0005f86fecbd6d0257b15363a5b013446914265";
    hash = "sha256-7tHS1PZMb9aYgzJyKKGcZOLc5ekLffek7tNHss3VEPQ=";
  };

  nanopb = pkgs.fetchgit {
    url = "https://github.com/nanopb/nanopb.git";
    rev = "cad3c18ef15a663e30e3e43e3a752b66378adec1";
    hash = "sha256-bMSZZaF8egAegi3enCM+DRyxOrPoWKAKybvWsrKZEDc=";
  };

  opensbi = pkgs.fetchgit {
    url = "https://github.com/riscv-software-src/opensbi.git";
    rev = "234ed8e427f4d92903123199f6590d144e0d9351";
    hash = "sha256-W39R1RHsIM3yNwW/eukO+mPd9joPZLw+/XIJoH8agN8=";
  };

  seL4 = pkgs.fetchgit {
    url = "https://github.com/seL4/seL4.git";
    rev = "6df0b6ee61f6a9e8a4ee7de8eb8fd698c0211b64";
    hash = "sha256-lLfCairfwjpPNvWcv1bjsfZ6yXFMspMr0mbB1fleH3U=";
  };

  seL4_libs = pkgs.fetchgit {
    url = "https://github.com/seL4/seL4_libs.git";
    rev = "262a34dcb2f3285be01df9e5404d911132d567a6";
    hash = "sha256-9+2GeDNITcqB1qZ6mbGexnZXoM46OpDS+L4WxUVBC/8=";
  };

  seL4_tools = pkgs.fetchgit {
    url = "https://github.com/seL4/seL4_tools.git";
    rev = "f1f63d93301cf491abc2d38ffb1a97803c218b31";
    hash = "sha256-/ULxJ7VqoOczcbZal+6SV2n9acTRmofaupYNK0E8rkw=";
  };

  seL4_projects_libs = pkgs.fetchgit {
    url = "https://github.com/seL4/sel4_projects_libs.git";
    rev = "fe2647c2582cd22a83e07491bb281ce061324b81";
    hash = "sha256-jcx8Ok0oukNJltw/80nGv37rHeAS58aZbX2VCfi5W78=";
  };

  sel4runtime = pkgs.fetchgit {
    url = "https://github.com/seL4/sel4runtime.git";
    rev = "86489cf6efab9f314964e79468c036e9035394c7";
    hash = "sha256-7H45pmcJd9e25Jgb52cp8Mj/CciQJzN9hz7HH1PJwYI=";
  };

  sel4test = pkgs.fetchgit {
    url = "https://github.com/seL4/sel4test.git";
    rev = "b00d84fca8890e34f6007f104372fec5e82a23d1";
    hash = "sha256-ypTx0npaDxna3PDJ4Av9GdhK/8vb6AZm/Uplmk9xxgw=";
  };

  util_libs = pkgs.fetchgit {
    url = "https://github.com/seL4/util_libs.git";
    rev = "8dd23f736664fe61aefc25ea45ffff8127bcdf2b";
    hash = "sha256-xPcETOTgtlwC59BNZQ0XkJeTSTRZIqfcf1+zrVv2wqI=";
  };

  seL4Test = pkgs.stdenv.mkDerivation {
    pname = "seL4Test";

    # Manifest taken from this commit of seL4/sel4test-manifest
    version = "822dbeef1a833a64aecef8965e58d4123af6cd71";

    # We don't use the manifest as the source tree.  It is only the
    # declaration of what should be assembled.
    src = null;

    nativeBuildInputs = with pkgs; [
      cmake
      ninja
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

    dontConfigure = true;

    unpackPhase = "true";

    buildPhase = ''
      mkdir -p $out

      # kernel/
      cp -a ${seL4} $out/kernel

      # projects/
      mkdir -p $out/projects

      cp -a ${musllibc} \
        $out/projects/musllibc

      cp -a ${seL4_libs} \
        $out/projects/seL4_libs

      cp -a ${seL4_projects_libs} \
        $out/projects/seL4_projects_libs

      cp -a ${sel4runtime} \
        $out/projects/sel4runtime

      cp -a ${sel4test} \
        $out/projects/sel4test

      cp -a ${util_libs} \
        $out/projects/util_libs

      # tools/
      mkdir -p $out/tools

      cp -a ${nanopb} \
        $out/tools/nanopb

      cp -a ${opensbi} \
        $out/tools/opensbi

      cp -a ${seL4_tools} \
        $out/tools/seL4

      # repo manifest linkfiles
      ln -s tools/seL4/cmake-tool/init-build.sh \
        $out/init-build.sh

      ln -s tools/seL4/cmake-tool/griddle \
        $out/griddle

      ln -s projects/sel4test/easy-settings.cmake \
        $out/easy-settings.cmake
    '';

    installPhase = "true";
  };

  seL4Test-shell = pkgs.mkShell {
    packages = seL4Test.nativeBuildInputs;

    shellHook = ''
      # shellHook specific version of
      # hardeningDisable = [ "stackprotector" ];
      export NIX_HARDENING_ENABLE=""

      # init-build.sh fails without the $HOME variable
      # if [ -z "''${HOME:-}" ]; then
      #   export HOME="$PWD/.home"
      # fi
      # mkdir -p "$HOME"
    '';
  };

in {
  inherit
    seL4Test
    seL4Test-shell;
}
