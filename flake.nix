{
  description = "f2l.cc";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/25.05";
  };

  outputs = { self, nixpkgs }: let
    forAllSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  in {
    devShells = forAllSystems (system: let
      pkgs = import nixpkgs { inherit system; };
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [
          # pin hugo at old version
          hugo
        ];
      };
    });
  };
}
