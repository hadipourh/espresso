{
  pkgs ? import <nixpkgs> { },
  ...
}:

pkgs.stdenv.mkDerivation {
  name = "espresso-formatter";

  src = ./format.sh;

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/format.sh
    chmod +x $out/bin/format.sh

    cat > $out/bin/format-all.sh <<'EOF'
    #!/usr/bin/env bash
    treefmt --tree-root "$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
    exec "$(dirname "$0")/format.sh" "$@"
    EOF
    chmod +x $out/bin/format-all.sh

    makeWrapper \
      $out/bin/format-all.sh \
      $out/bin/espresso-formatter \
      --set PATH "${pkgs.clang-tools}/bin:${pkgs.cmake-format}/bin:${pkgs.git}/bin:${pkgs.nixfmt-tree}/bin:${pkgs.prettier}/bin:${pkgs.shfmt}/bin:$PATH"
  '';

  nativeBuildInputs = with pkgs; [ makeWrapper ];
}
