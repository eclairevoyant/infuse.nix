# Design notes on leafless attrsets

Removing leafless attrsets from an infusion before infusing it is not just a
performance optimization.  It is important that `infuse target { a.b.c = {}; }`
does not create an attribute `a` if none existed already in `target`.

The naive implementation, which checks for "is leafless" from within
`flip-infuse-desugared-pruned`, has O(n^2) worst-case complexity, because
knowing that `a` is leafless requires traversing arbitrarily deep (in this case,
to `a.b.c`).  Therefore to preserve O(n) worst-case complexity we have to check
for leafless attrsets in a separate pass.
