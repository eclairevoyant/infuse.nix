# Design notes on representation of "missing" target attributes:

There are basically three ways to represent the "previous value" when infusing
to a missing attribute:

1. Represent functions which can tolerate (or are sensitive to) a missing
   previous value using { __functor = ... }.

   - Downsides: invalidates eta-expansion, identity function is no longer
     the left/right identity for function composition

2. Use a special "missing value" marker

   - Downsides: although we can exploit function equality to create an
     "unforgeable gensym", it isn't a `throw`.  So if it leaks outside of
     infuse, ordinary functions might not force enough of the missing value
     to trigger the error that they should experience.

3. Use the Nix "missing attribute" value.

   You can't see this from inside the language, but if you ever try
   implementing a Nix interpreter it quickly becomes clear that the
   "value" enum/union needs to have a branch that represents `{}.foo`
   so that `{}.foo or false` can be implemented correctly.
   
   - Downsides: infusion leaf attributes would need to be functions
     which take one-attribute attrsets (i.e. `{x?false}: ...` instead
     of `x: ...`), which would require wrapping every infusion
     argument in an extra heap-allocated attrset.  This causes a very
     large load on the garbage collector in the most-common path.  The
     performance costs are very significant.

Although the first approach is preferable, it breaks the left identity rule for
list infusions because these two infusions no longer do the exact same thing:

```
{ y = [    { __init = 7; } ]; }
{ y = [ [] { __init = 7; } ]; }
```

(there is a test case to check that the identity law is not violated).

Since the first approach is semantically unsound and the third
approach has major performance costs, we choose the second approach.

