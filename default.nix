{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;
stdenv.mkDerivation {
	buildInputs = [ pandoc ];
	name = "christianfscott.com";
}
