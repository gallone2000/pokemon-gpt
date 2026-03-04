{
  description = "FastAPI (nixpkgs python packages, no venv)";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system:
        let pkgs = import nixpkgs { inherit system; }; in f pkgs
      );
    in
    {
      packages = forAllSystems (pkgs:
        let
          python = pkgs.python314;
          pyEnv = python.withPackages (ps: with ps; [ fastapi uvicorn ]);
        in {
          inherit pyEnv;
          default = pyEnv;
        }
      );

      devShells = forAllSystems (pkgs:
        let
          python = pkgs.python314;
          pyEnv = python.withPackages (ps: with ps; [ fastapi uvicorn ]);
        in {
          default = pkgs.mkShell {
            packages = [ pyEnv pkgs.git ];
          };
        }
      );
    };
}