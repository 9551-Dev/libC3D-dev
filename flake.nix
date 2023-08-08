{
  description = "C3D";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.illuaminate.url = "github:SquidDev/illuaminate";

  outputs = { self, nixpkgs, flake-utils, illuaminate }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShell = pkgs.mkShell {
          packages = [ illuaminate.packages.${system}.illuaminate-full ];
        };
      });
}
