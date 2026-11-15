{ stdenv, fetchurl, autoPatchelfHook }:
stdenv.mkDerivation {
  pname = "waybar-timer";
  version = "0.4";
  src = fetchurl {
    url = "https://github.com/jbirnick/waybar-timer/releases/download/v0.4/waybar_timer";
    sha256 = "5542d6978e417c3fa495b696b47ea6e6b59696dfac41f72fb65fcbc62081c6fe";
  };
  dontUnpack = true;
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];
  installPhase = ''
    install -Dm755 "$src" "$out/bin/waybar_timer"
  '';
  meta.platforms = [ "x86_64-linux" ];
}
