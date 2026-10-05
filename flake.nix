{
  description = "Mesa gfxstream Vulkan guest driver";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      wrapCache = pkgs.runCommand "mesa-gfxstream-wrap-cache" { } ''
        mkdir -p "$out"
        for archive in ${pkgs.mesa.env.MESON_PACKAGE_CACHE_DIR}/*; do
          ln -s "$archive" "$out/$(basename "$archive")"
        done
        ln -s ${
          pkgs.fetchurl {
            url = "https://static.crates.io/crates/rustix/1.1.4/download";
            sha256 = "b6fe4565b9518b83ef4f91bb47ce29620ca828bd32cb7e408f0062e9930ba190";
          }
        } "$out/rustix-1.1.4.tar.gz"
        ln -s ${
          pkgs.fetchurl {
            url = "https://static.crates.io/crates/libc/0.2.185/download";
            sha256 = "52ff2c0fe9bc6cb6b14a0592c2ff4fa9ceb83eea9db979b0487cd054946a2b8f";
          }
        } "$out/libc-0.2.185.tar.gz"
      '';
    in
    {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        pname = "mesa-gfxstream";
        version = "26.3.0-devel";
        src = ./.;

        nativeBuildInputs = pkgs.mesa.nativeBuildInputs;
        buildInputs = pkgs.mesa.buildInputs;
        env.MESON_PACKAGE_CACHE_DIR = wrapCache;

        mesonFlags = [
          "-Dauto_features=disabled"
          "-Dplatforms=x11"
          "-Dvulkan-drivers=gfxstream"
          "-Dgallium-drivers="
          "-Dopengl=false"
          "-Dllvm=disabled"
          "-Dgbm=disabled"
          "-Dglvnd=disabled"
          "-Degl=disabled"
          "-Dglx=disabled"
          "-Dvirtgpu_kumquat=true"
          "-Dbuild-tests=false"
        ];
      };

      devShells.${system}.default = pkgs.mkShell {
        inputsFrom = [ pkgs.mesa ];
      };
    };
}
