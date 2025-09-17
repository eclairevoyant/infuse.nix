{
  inputs.nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";

  outputs =
    { nixpkgs-lib, ... }:
    {
      lib = import ./. { inherit (nixpkgs-lib) lib; };
    };
}
