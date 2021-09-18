#! /usr/bin/env bash

exit 0

if command -v nix-shell > /dev/null
then
  nix-shell --command bash default.nix <<< ./generate.sh
else
  ./generate.sh
fi
