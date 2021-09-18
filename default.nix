{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;
stdenv.mkDerivation {
	buildInputs = [ jq pandoc ];
	name = "christianfscott.com";
}
