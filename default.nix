{
  pkgs ? import <nixpkgs> { },
  ...
}:

pkgs.stdenv.mkDerivation {
  pname = "espresso";
  version = "3.0.1";
  src = ./.;
  nativeBuildInputs = [ pkgs.cmake ];
}
