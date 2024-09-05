#!/usr/bin/env -S nix-instantiate --eval --arg dummy null --show-trace
# `--arg dummy null` is needed in order to trigger default args behavior

#
# TODO:
# - Need test cases to check that `sugars` are applied in proper order
#
#


{ lib ? pkgs.lib
# pinned in order to keep the tests deterministic
, pkgs ? import (builtins.fetchTarball {
    url = "https://github.com/nixos/nixpkgs/archive/01f288e3beededa8293af1ad6e5747caba2dbcda.tar.gz";
    sha256 = "1dks0p4xbm2p7wkjkkpp16hv31cybv60r8y11pxhly24vm5ayv1p";
  }) {}

# tests should pass with this parameter set to any integer value assuming no
# overflow (TODO: something like quickcheck, sweep over a bunch of values)
, any-integer ? 4
, any-integer2 ? 100212

, ...
}:
let
  inherit (lib) flip pipe zipAttrs id mapAttrs;
  inherit (builtins) tryEval deepSeq;
  inherit (import ./.. { inherit lib; }) v1;

  # we want to test the optimizer too
  infuse = target: infusion: v1.infuse target (v1.optimize infusion);

  toPretty = v: lib.generators.toPretty {} v;
  tryEvalDeep = expr: tryEval (deepSeq expr expr);
  expect-throw = test: (tryEvalDeep test).success == false;

  zipAttrsWithPipe =
    name:
    value:
    x: pipe x value;

  # wraps its argument in `{ y = ...; }` as a one-attribute attrset
  lift-y = y: { inherit y; };

  # these are used as trivial example functions for identity/associativity laws
  inc       = x: x+1;
  squared   = x: x*x;
  cubed     = x: x*x*x;
  y-inc     = { y = inc;     };
  y-squared = { y = squared; };
  y-cubed   = { y = cubed;   };
  y-any-integer = { y = any-integer; };

  equal-infusions =
    first-infusion:
    second-infusion:
    infuse { x = any-integer2; y = any-integer; } first-infusion
    == infuse { x = any-integer2; y = any-integer; } second-infusion;

  assert-eq = a: b:
    let
      result = a == b;
    in
      if result
      then true
      else lib.warn "${toPretty a}" (lib.warn "${toPretty b}" result);

  # Apply each attrvalue of `functions` to the attrvalue of `values` with the
  # same name.
  applyAttrs =
    functions:    # Attrs<Function>
    values:       # Attrs<Any>
    values //
    mapAttrs
      (name: function:
        function (values.${name}
          or throw "values.${name} is missing"))
      functions;

in

assert
  (infuse {
    foo.update = 2;
  } {
    foo.update = x: x + 1;
    foo.newattr = _: 9;
  })
  == {
    foo.update = 3;
    foo.newattr = 9;
  };

# readme examples
assert        ({ bob.fred = 3; } // { bob.jill = 4; }) == { bob.jill = 4; };
assert (infuse { bob.fred = 3; } { bob.jill = _: 4; }) == { bob.fred = 3; bob.jill = 4; };
assert (infuse { bob.fred = 3; } { bob = _: { jill = 4; }; }) == { bob.jill = 4; };
assert (infuse { bob.fred = 3; } { bob.fred = [ (x: x + 1) (x: x * x) ]; }) == { bob.fred = 16; };
assert (infuse { bob.fred.x = 3; } { bob.fred = [{ x = x: x * x; } (fred: fred.x + 1)]; }) == { bob.fred = 10; };
assert (infuse
   { bob.fred.x = 3; }
   { bob.fred = [ { x = x: x*x; } (fred: fred.x+1) ]; }
==
   { bob.fred = 10; });
assert (infuse
   { x = 3; }
   [ { x = x: x*x; } (fred: fred.x+1) ]
==
   10);

# function
assert (infuse { a = 3; } (lib.mapAttrs (_: v: v * v))) == { a = 9; };

# list
assert (infuse { a.b = 3; } { a.b = [ (x: x + 1) (x: x * x) ]; }) == { a.b = 16; };

# __assign
assert (infuse { a.b = 3; } { a.b.__assign = 9; }) == { a.b = 9; };
assert (infuse { a.b = 3; } { a.__assign = 9; }) == { a = 9; };
assert (infuse { a.b = 3; } { a.__assign = { c = 7; }; }) == { a.c = 7; };
assert (infuse { a.b = 3; } { a.__assign.__default = 3; }) == { a.__default = 3; };

# __default
assert (infuse { a.b = 3; } { a.b.__default = 9; }) == { a.b = 3; };
assert (infuse { a.b = 3; } { a.q.__default = 9; }) == { a.b = 3; a.q = 9; };
assert (infuse { a.b = 3; } { a.q.__default.__default = 9; }) == { a.b = 3; a.q.__default = 9; };

# __init
assert (infuse { x = 4; } [ lib.id { y.__init = 7; } ] == { x = 4; y = 7; });
assert (infuse { a.b = 3; } { a.q.__init = 9; }) == { a.b = 3; a.q = 9; };
assert expect-throw (infuse { a.b = 3; } { a.b.__init = 9; });
assert (infuse { } { a.__init.__assign = 9; }) == { a.__assign = 9; };

# __prepend
assert (infuse { } { a.b.__prepend = "fred"; }) == { a.b = "fred"; };
assert (infuse { a.b = "bob"; } { a.b.__prepend = "fred"; }) == { a.b = "fredbob"; };
assert (infuse { } { a.b.__prepend = [ "fred" ]; }) == { a.b = [ "fred" ]; };
assert (infuse { a.b = [ "bob" ]; } { a.b.__prepend = [ "fred" ]; }) == { a.b = [ "fred" "bob" ]; };
assert expect-throw (infuse { a = []; } { a.__prepend = { c = 7; }; });
assert expect-throw (infuse { a = []; } { a.__prepend = x: x; });
assert expect-throw (infuse { a = ""; } { a.__prepend = { c = 7; }; });
assert expect-throw (infuse { a = ""; } { a.__prepend = x: x; });

# __append
assert (infuse { } { a.b.__append = "fred"; }) == { a.b = "fred"; };
assert (infuse { a.b = "bob"; } { a.b.__append = "fred"; }) == { a.b = "bobfred"; };
assert (infuse { } { a.b.__append = [ "fred" ]; }) == { a.b = [ "fred" ]; };
assert (infuse { a.b = [ "bob" ]; } { a.b.__append = [ "fred" ]; }) == { a.b = [ "bob" "fred" ]; };
assert expect-throw (infuse { a = []; } { a.__append = { c = 7; }; });
assert expect-throw (infuse { a = []; } { a.__append = x: x; });
assert expect-throw (infuse { a = ""; } { a.__append = { c = 7; }; });
assert expect-throw (infuse { a = ""; } { a.__append = x: x; });

# __infuse
assert (infuse { a.b = "bob"; } { a.b.__infuse = x: "${x}-fred-${x}"; }) == { a.b = "bob-fred-bob"; };
assert (infuse { a.b = "bob"; } { a.__infuse = { c = _: "jill"; }; }) == { a.b = "bob"; a.c = "jill"; };
assert (infuse { a.b = "bob"; } { a.__infuse = { c.__init = "jill"; }; }) == { a.b = "bob"; a.c = "jill"; };

# __input and __output, in a real-world testcase
assert
  (infuse pkgs.xrdp {
    __input.systemd.__assign = null;
    __output.env.NIX_CFLAGS_COMPILE.__append = " -w";
    __output.passthru.xorgxrdp.__output.configureFlags.__append = ["--without-fuse"];
  })

  ==

  ((pkgs.xrdp.override {
    systemd = null;
  })
    .overrideAttrs(previousAttrs: {
      env = previousAttrs.env or {} // {
        NIX_CFLAGS_COMPILE =
          (previousAttrs.env.NIX_CFLAGS_COMPILE or "")
          + " -w";
      };
      passthru = previousAttrs.passthru or {} // {
        xorgxrdp = previousAttrs.passthru.xorgxrdp
          .overrideAttrs (previousAttrs: {
            configureFlags = (previousAttrs.configureFlags or []) ++ [
              "--without-fuse"
            ];
          });
      };
    }))
;




##############################################################################
##
## Algebraic laws of `infuse`
##
##############################################################################

# 1. On a list-of-functions, `flip infuse` is exactly `flip pipe`
# 2. On a list-of-attrsets, `flip infuse` is `flip pipe [ zipAttrs infuse ]`
# 3. On an attrset-of-functions, `flip infuse` acts like `applyAttrs`

#
#   Ye Olde Commutative Diagram of pain:
#
#   I believe there is a Universal Property for infusion -- a reason why it is
#   the uniquely determined minimal operation that does what it does -- due to
#   being the initial algebra of some (not-yet-clearly-stated) endofunctor on
#   the category of Nix values... but I need to spell that out.
#
#   The important part is that it respects the structure of the monoid
#   operations (attrset-update, list concatenation, and function composition) on
#   **all three** of Nix's three nonprimitive types (attrsets, lists, and
#   functions).  Additionally, the preexisting monoid-preserving maps
#   (zipAttrs, pipe, and applyAttrs) commute with `infuse` as shown in the
#   diagram below.  I think that probably makes infuse a natural transformation
#   in some way, but it's only a hunch right now.
#
#                                                                 zipAttrs
#       [  { y = foo; } ... { y = bar; } { x = baz; } ]  ------------------------>      { y = [ foo ... bar ];  x = baz; }
#                                  |                                                                  |
#                                  |                                                                  |
#  map (mapAttrs (_: flip infuse)) |                                                                  |     mapAttrs (_: flip infuse)
#                                  |                                                                  |
#                                  v                                                                  v
#    [ { y = foo'; } ... { y = bar'; } { x = baz'; } ]                                { y = [ foo' ... bar' ];  x = baz'; }
#                                  |                                                                  |
#                                  |                                                                  |
#                  map applyAttrs  |                                                                  |  applyAttrs
#                                  |                                                                  |
#                                  v                                                                  v
#  [ (applyAttrs {y=foo';}) ... (applyAttrs {y=bar';}) (applyAttrs {x=baz';}) ]    ----->  (a: { y = bar' (foo' a.y); x = baz' a.x; })
#                                                                                flip pipe
#


# list infusions: identity and associativity
assert equal-infusions
  [    y-squared [] ]
  [ [] y-squared    ];
assert equal-infusions
  y-squared
  [ [] y-squared    ];
assert equal-infusions
  [ [ y-squared   y-cubed ] y-inc ]
  [   y-squared [ y-cubed   y-inc ] ];

# attrset infusions: identity and associativity
assert equal-infusions
  [    y-squared {} ]
  [ {} y-squared    ];
assert
  flip infuse (lift-y (flip infuse [ squared inc ]))  y-any-integer
  ==
  flip pipe (map (flip infuse)   (map lift-y [ squared inc ]))   y-any-integer;

# distributive law of `lib.pipe` over `flip infuse` (for lists)
assert lib.pipe { y = any-integer; } (map (flip infuse) [ [ { y =   squared; } { y = inc; } ]      ])
  ==   lib.pipe { y = any-integer; } (map (flip infuse) [   { y =   squared; } { y = inc; }        ]);

# distributive law of `{}` over `[]` for one-element attrsets
assert equal-infusions
            [ { y =   squared; } { y = inc; } ]
  (zipAttrs [ { y =   squared; } { y = inc; } ]);


##############################################################################
##
## Test cases demonstrating non-obvious properties of `infuse`:
##
##############################################################################

# although you might think that `t: infuse t {}` is the same as `lib.id` that's
# not quite correct: the former must fail when the argument isn't an attrset.
assert expect-throw ((infuse 3 { }) == null);

# infusing an empty set to an attribute that does not exist should not create it
assert (infuse { } { x = {}; }) == { };
assert (infuse { } { x.y.z.fred.bob = {}; }) == { };
assert (infuse { } [{ x.y.z.fred.bob = {}; }]) == { };

# however, infusing the identity function or the empty list (which is equivalent
# to the identity function) to an attribute which does not exist will `throw`:
assert expect-throw (infuse { } { x = []; });
assert expect-throw (infuse { } { x.y.z.fred.bob = []; });
# but of course the `throw` in the previous test isn't a problem if it isn't forced.
assert              (infuse { } { x.y.z.fred.bob = []; x.y.q.__assign = 3; }).x.y.q == 3;

# make sure the `infuse.missing` value does not leak out to the return value of `infuse`
assert expect-throw (infuse { x = 4; } { y = z: z; }).y;
assert expect-throw (infuse { x = 4; } { y = []; }).y;

# however we can pass `infuse.missing` along a pipeline:
assert (infuse { x = 4; } { y = [ (_: 3) ]; } == { x = 4; y = 3; });
# the following test will fail if `flip-pipe-lazy` is replaced with `flip pipe`
assert (infuse { x = 4; } { y = [ (x: x) (_: 3) ] ; } == { x = 4; y = 3; });

# we also need to check the "distributive law" for these error cases:
assert (infuse { x = 4; } [ { y = lib.id; } { y = _: 3; } ] == { x = 4; y = 3; });
assert (lib.pipe { x = 4; } [ (lib.flip infuse { y = lib.id; }) (lib.flip infuse { y = _: 3; }) ] == { x = 4; y = 3; });

# infusing a boolean, integer, float, or null is undefined
assert expect-throw (infuse {} { x = 3;     });
assert expect-throw (infuse {} { x = 3.14;  });
assert expect-throw (infuse {} { x = false; });
assert expect-throw (infuse {} { x = null;  });

# infusing to a derivation is not (currently) allowed
assert
  let
    drv = builtins.derivation {
      name = "name";
      builder = "/bin/sh";
      system = builtins.currentSystem;
    };
  in expect-throw (infuse { name.__append = "s are important"; } drv);


"all tests passed"



