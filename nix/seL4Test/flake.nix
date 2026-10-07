{
  description = "seL4Test building flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Contains default.xml, common.xml, and master.xml.
    seL4TestManifestSrc = {
      url = "github:seL4/sel4test-manifest";
      flake = false;
    };

    # kernel
    seL4Src = {
      url = "github:seL4/seL4/6df0b6ee61f6a9e8a4ee7de8eb8fd698c0211b64";
      flake = false;
    };

    # projects/musllibc
    musllibcSrc = {
      url = "github:seL4/musllibc/b0005f86fecbd6d0257b15363a5b013446914265";
      flake = false;
    };

    # projects/seL4_libs
    seL4LibsSrc = {
      url = "github:seL4/seL4_libs/262a34dcb2f3285be01df9e5404d911132d567a6";
      flake = false;
    };

    # projects/sel4_projects_libs
    seL4ProjectsLibsSrc = {
      url = "github:sel4proj/sel4_projects_libs/fe2647c2582cd22a83e07491bb281ce061324b81";
      flake = false;
    };

    # projects/sel4runtime
    seL4RuntimeSrc = {
      url = "github:seL4/sel4runtime/86489cf6efab9f314964e79468c036e9035394c7";
      flake = false;
    };

    # projects/sel4test
    seL4TestSrc = {
      url = "github:seL4/sel4test/b00d84fca8890e34f6007f104372fec5e82a23d1";
      flake = false;
    };

    # projects/util_libs
    utilLibsSrc = {
      url = "github:seL4/util_libs/8dd23f736664fe61aefc25ea45ffff8127bcdf2b";
      flake = false;
    };

    # tools/seL4
    seL4ToolsSrc = {
      url = "github:seL4/seL4_tools/f1f63d93301cf491abc2d38ffb1a97803c218b31";
      flake = false;
    };

    # tools/nanopb
    nanopbSrc = {
      url = "github:nanopb/nanopb/cad3c18ef15a663e30e3e43e3a752b66378adec1";
      flake = false;
    };

    # tools/opensbi
    #
    # The manifest uses github.com/riscv/opensbi, which now redirects to
    # the canonical riscv-software-src organization.
    opensbiSrc = {
      url = "github:riscv-software-src/opensbi/234ed8e427f4d92903123199f6590d144e0d9351";
      flake = false;
    };
  };

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      crossPkgs = pkgs.pkgsCross.aarch64-multiplatform;
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          cmake
          ninja
          git
          python3
          dtc

          (python3.withPackages (ps: [
            ps.pyyaml
            ps.pyfdt
            ps.jinja2
          ]))

          crossPkgs.stdenv.cc
        ];

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
    };
}
