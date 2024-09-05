#!/usr/bin/env -S nix-instantiate --eval --arg dummy null --show-trace
# `--arg dummy null` is needed in order to trigger default args behavior

{ lib ? pkgs.lib
# pinned in order to keep the tests deterministic
, pkgs ? import (builtins.fetchTarball {
    url = "https://github.com/nixos/nixpkgs/archive/01f288e3beededa8293af1ad6e5747caba2dbcda.tar.gz";
    sha256 = "1dks0p4xbm2p7wkjkkpp16hv31cybv60r8y11pxhly24vm5ayv1p";
  }) {}
}:

let
  infuse = import ../default.nix {
    inherit lib;
    sugars = infuse.v1.default-sugars ++ lib.attrsToList {
      __concatStringsSep =
        path: infusion: target:
        lib.strings.concatStringsSep infusion target;
    };
  };
in
  infuse.v1.infuse
    { fred = [ "woo" "hoo" ]; }
    { fred.__concatStringsSep = "-"; }
  ==
    { fred = "woo-hoo"; }

