{
  description = "FastAPI dev shell (uv-managed)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system:
        f (import nixpkgs { inherit system; })
      );
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.python314
            pkgs.python314Packages.pip
            pkgs.uv
            pkgs.git
          ];

          # opzionale: uv usa cache sua; niente venv auto qui
          # (uv di default crea .venv quando fai "uv sync")
        };
      });
    };
}