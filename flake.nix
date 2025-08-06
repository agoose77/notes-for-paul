# code-owner: @agoose77
# This flake sets up an FSH dev-shell that installs all the required
# packages for running deployer, and then installs the tool in the virtual environment
# It is not best-practice for the nix-way of distributing this code,
# but its purpose is to get an environment up and running.
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      inherit (pkgs) lib;

      node = pkgs.nodejs_22;
      packages = [node];
      shellHook = ''
        # Setup if not defined ####
        if [[ ! ( -d "node_modules" && -f "node_modules/marker" ) ]]; then
            __setup_env() {
                # Remove existing venv
                if [[ -d node_modules ]]; then
                    rm -r node_modules
                fi

                # Stand up new venv
                ${lib.getExe' node "npm"} install --no-save mystmd

                # Add a marker that marks this venv as "ready"
                touch node_modules/marker
            }

            __setup_env
        fi
        ###########################
        export PATH="$PATH:$PWD/node_modules/.bin"

      '';
    in {
      devShell = pkgs.mkShell {
        inherit packages shellHook;
      };
    });
}
