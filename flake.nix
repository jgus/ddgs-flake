{
  description = "ddgs: version-bumped ahead of nixpkgs through a Python package overlay.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-lib = {
      url = "github:jgus/flake-lib/v1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { nixpkgs, flake-utils, flake-lib, ... }:
    let
      pin = import ./pin.nix;
      inherit (pin) version hash;
      source = { type = "pypi"; pname = "ddgs"; format = "sdist"; };
      overlay = final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (pyfinal: pyprev: {
            ddgs = pyprev.ddgs.overridePythonAttrs (prevAttrs: {
              inherit version;
              doCheck = false;
              dependencies = (prevAttrs.dependencies or [ ]) ++ [
                pyfinal.fake-useragent
                pyfinal.httpx
              ];
              src = pyfinal.fetchPypi { inherit version hash; pname = "ddgs"; };
            });
          })
        ];
      };
    in
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in
        {
          packages = {
            ddgs = pkgs.python3.pkgs.ddgs;
            default = pkgs.python3.pkgs.ddgs;
            update-version = flake-lib.lib.mkUpdateVersion { inherit pkgs source; buildAttr = "ddgs"; };
            update-branches = flake-lib.lib.mkUpdateBranches { inherit pkgs source; pinSchema = "pypi"; };
          };
        }) // {
      overlays.default = overlay;
    };
}
