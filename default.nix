{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;

stdenv.mkDerivation {
	buildInputs = [ bazelisk jq pandoc ];
	name = "christianfscott.com";
}
