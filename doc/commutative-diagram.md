# Ye Olde Commutative Diagram of pain

I believe there is a Universal Property for infusion -- a reason why it is the
uniquely determined minimal operation that does what it does -- due to being the
initial algebra of some (not-yet-clearly-stated) endofunctor on the category of
Nix values... but I need to spell that out.

The important part is that it respects the structure of the monoid operations
(attrset-update, list concatenation, and function composition) on **all three**
of Nix's three nonprimitive types (attrsets, lists, and functions):

1. On a list-of-functions, `flip infuse` is exactly `flip pipe`
2. On a list-of-attrsets, `flip infuse` is `flip pipe [ zipAttrs infuse ]`
3. On an attrset-of-functions, `flip infuse` acts like `applyAttrs = flip pipe [ (flip getAttr) mapAttrs ]`

Additionally, the preexisting monoid-preserving maps (`zipAttrs`, `pipe`, and
`applyAttrs`) commute with `infuse` as shown in the diagram below.  I think that
probably makes infuse a natural transformation in some way, but it's only a
hunch right now.

```
# abbreviations to improve readability of diagram
let
  foo' = flip infuse foo
  bar' = flip infuse bar
  baz' = flip infuse baz
in
                                                              zipAttrs
     [  { y = foo; } ... { y = bar; } { x = baz; } ]  ------------------------>      { y = [ foo ... bar ];  x = baz; }
                                |                                                                  |
                                |                                                                  |
map (mapAttrs (_: flip infuse)) |                                                                  |     mapAttrs (_: flip infuse)
                                |                                                                  |
                                v                                                                  v
 [ { y = foo'; } ... { y = bar'; } { x = baz'; } ]                                { y = [ foo' ... bar' ];  x = baz'; }
                                |                                                                  |
                                |                                                                  |
                map applyAttrs  |                                                                  |  applyAttrs
                                |                                                                  |
                                v                                                                  v
  [ (applyAttrs {y=foo';}) ... (applyAttrs {y=bar';}) (applyAttrs {x=baz';}) ]    ----->  (a: { y = bar' (foo' a.y); x = baz' a.x; })
                                                                                flip pipe

```
