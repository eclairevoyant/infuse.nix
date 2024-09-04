run-tests:
        nix-instantiate --eval --arg dummy null --show-trace tests/default.nix
