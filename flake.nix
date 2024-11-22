{
  description = "A flake that's used to develop this project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
          otp = pkgs.beam.packages.erlangR26;
        in
        {
          devShells.default = pkgs.mkShell {
            buildInputs = [ otp.elixir pkgs-unstable.zig pkgs.xz pkgs.p7zip ];
            ERL_AFLAGS = "-kernel shell_history enabled";

            shellHook = ''
              mkdir -p .nix-mix .nix-hex
              export MIX_HOME=$PWD/.nix-mix
              export HEX_HOME=$PWD/.nix-hex
              export ELIXIR_ERL_OPTIONS="+fnu"

              export MIX_PATH="${otp.hex}/lib/erlang/lib/hex/ebin"
              export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH
            '';
          };
        }
      );
}
