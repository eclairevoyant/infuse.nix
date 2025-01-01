# infuse.nix

- canonical repository: [https://codeberg.org/amjoseph/infuse.nix](https://codeberg.org/amjoseph/infuse.nix).
- questions: `#six/hackint` (be patient, i am asynchronous)
- the commutative diagram alluded to in the 38c3 talk is in [`doc/commutative-diagram.md`](./doc/commutative-diagram.md)

## What?

`infuse` is a "deep" version of both `.override` and `.overrideAttrs` which
generalizes both `lib.pipe` and `recursiveUpdate`.  It can be used as a leaner,
untyped alternative to `lib.modules`.  If you want dynamic typechecking, it
works well with [yants](https://code.tvl.fyi/tree/nix/yants/README.md).  Infusion has [specified semantics](default.nix#L47) which
[preserve identity and associativity laws](#semantics) at all three of nix's non-finite types

## Why?

Would you rather write this:

```nix
final: prev: {

  python311 = prev.python311.override
    (previousArgs: previousArgs // {
      packageOverrides =
        lib.composeExtensions
          (previousArgs.packageOverrides or {})
          (final: prev: {
            dnspython = prev.dnspython.overrideAttrs(previousAttrs: {
              doCheck = false;
            });
          });
    });

  xrdp = (prev.xrdp.override {
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
    });
}
```

... or this?

```nix
final: prev: infuse prev {

  python311.__input.packageOverrides.__overlay.dnspython.__output.doCheck.__assign = false;

  xrdp.__input.systemd.__assign = null;
  xrdp.__output.env.NIX_CFLAGS_COMPILE.__append = " -w";
  xrdp.__output.passthru.xorgxrdp.__output.configureFlags.__append = ["--without-fuse"];

}
```

If you think the second expression is easier to read, write, and maintain, you
would probably be interested in `infuse.nix`.


## How?

The basic idea is that when its second argument is an attrset, `infuse` acts
like `lib.recursiveUpdate`, except that in the second argument you must *mark*
any subtrees where you want the automatic merging to stop.  You mark those
subtrees by changing them from whatever value they were into a function which
returns that value (and ignores its argument).

In the following example, `fred` gets clobbered because we used `//`:

```nix
       { bob.fred = 3; } // { bob.jill =    4;        } == { bob.jill = 4; }
```

If we instead use `infuse`, we end up with both `bob.fred` and `bob.jill`,
because we have marked `bob.jill` by making its value a function (`_: 4`):

```nix
infuse { bob.fred = 3; }    { bob.jill = _: 4;        } == { bob.fred = 3; bob.jill = 4; }
```

Unlike `lib.modules`, we can get back the "clobbering" behavior if we want, by
marking an attribute higher up the tree:

```nix
infuse { bob.fred = 3; }    { bob = _: { jill = 4; }; } == { bob.jill = 4; }
```

This allows to merge attrsets containing *structured* values which should
replace each other (or report an error) rather than getting mixed together.

### Lists

When the second argument is a list, `infuse` acts like `lib.pipe`:

```nix
infuse
   { x = 3; }
   [ { x = x: x*x; } (fred: fred.x+1) ]
==
   10
```

You can even mix lists with attrsets:

```nix
infuse
   { bob.fred.x = 3; }
   { bob.fred = [ { x = x: x*x; } (fred: fred.x+1) ]; }
==
   { bob.fred = 10; }
```

## There is No Magic Under the Hood

All those double-underscore attributes you see, like `__input` and `__output`
are just *sugar*.  You can omit them, or even define your own sugars:

```nix
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
```

The process of replacing these double-underscore attributes by expanded
definitions is called *desugaring*.  After desugaring, what's left is a
*desugared infusion*: an attrset whose leaf values are all functions -- no
integers, booleans, strings, etc.  In other words: it is an error to try to
infuse an attrset whose desugaring contains any non-function leaf values.

When you infuse a desugared infusion into a target, each function in the
infusion is applied to the target attrvalue which has the same attrpath.

## Semantics {#semantics}

Let's take a look at `lib.pipe`.  It has two important properties:

- `flip pipe []` does the same thing as `lib.id`
- `flip pipe (a ++ b)` does the same thing as `flip pipe [ (flip pipe a) (flip pipe b) ]`

Infuse has both of these properties as well, when used on lists:

- `flip infuse []` does the same thing as `lib.id`
- `flip infuse (a ++ b)` does the same thing as `flip pipe [ (flip infuse a) (flip infuse b) ]`

What makes `infuse` special is that it also works on attrsets, and does so *in
the same way* that it (and `lib.pipe`) work on lists:

- `flip infuse {}` does the same thing as `lib.id`
- `flip infuse (a // b)` does the same thing as `flip pipe [ (flip infuse a) (flip infuse b) ]`

In fact, `infuse` does the same trick for functions too!

- `flip infuse lib.id` does the same thing as `lib.id`
- `flip infuse (pipe [ a b ])` does the same thing as `flip pipe [ (flip infuse a) (flip infuse b) ]`

Most important of all, these are not three *separate* tricks (one for lists, one
for attrsets, and one for functions).  It is one single trick that works *at all
three of the non-finite Nix types* (lists, attrsets, and functions).

## Examples

For an example of what `infuse.nix` can do, see [amjoseph's overlays](examples/amjoseph-overlays.nix).


