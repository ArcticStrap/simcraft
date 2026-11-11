#!/usr/bin/env bash
# Regenerate every derived app icon from assets/app-icon/simcraft.svg (the canonical artwork; a
# 512-unit full-bleed tile with rx=112). simcraft-small.svg is an optimized trace for scalable
# icon themes.
#
# Needs: resvg (brew install resvg / cargo install resvg). On macOS, iconutil also writes the
# .icns. The outputs are committed, so builds and packaging never need these tools.
#
#   packaging/icons.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="$ROOT/assets/app-icon"
SVG="$DIR/simcraft.svg"
APP_ID="simcraft"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

command -v resvg >/dev/null || { echo "error: resvg not found (cargo install resvg)" >&2; exit 1; }

# macOS icons follow Apple's grid: the tile body is 824 of 1024 px with a transparent margin, so
# the Dock shows it at the same size as other apps. 512 * 1024 / 824 = 636.27 units, margin 62.14.
MAC="$TMP/mac.svg"
sed 's/viewBox="0 0 512 512"/viewBox="-62.14 -62.14 636.27 636.27"/' "$SVG" >"$MAC"
grep -q 'viewBox="-62.14' "$MAC" || { echo "error: unexpected viewBox in $SVG" >&2; exit 1; }

render() { resvg -w "$2" -h "$2" "$1" "$3" </dev/null; }

echo "Rendering high-resolution master and platform tiles..."
render "$SVG" 1024 "$DIR/simcraft-1024.png"
# Runtime window/Dock icon on macOS
render "$MAC" 512 "$DIR/simcraft-macos-512.png"

# Standard resolutions directly in assets/app-icon
render "$SVG" 16 "$DIR/simcraft-16.png"
render "$SVG" 32 "$DIR/simcraft-32.png"
render "$SVG" 64 "$DIR/simcraft-64.png"
render "$SVG" 256 "$DIR/simcraft-256.png"

# Linux hicolor theme. Windows and Linux use the full-bleed tile.
echo "Rendering Linux hicolor icon theme tree..."
for s in 16 24 32 48 64 128 256 512; do
  mkdir -p "$DIR/hicolor/${s}x${s}/apps"
  render "$SVG" "$s" "$DIR/hicolor/${s}x${s}/apps/$APP_ID.png"
done
mkdir -p "$DIR/hicolor/scalable/apps"
cp "$DIR/simcraft-small.svg" "$DIR/hicolor/scalable/apps/$APP_ID.svg"

# Windows .ico packing
echo "Packing Windows simcraft.ico..."
python3 - << 'PYEOF'
import os, struct, subprocess

tmp = os.environ.get("TMP", "/tmp")
svg = os.path.join(os.environ.get("DIR", "assets/app-icon"), "simcraft.svg")
out_ico = os.path.join(os.environ.get("DIR", "assets/app-icon"), "simcraft.ico")

sizes = [16, 20, 24, 32, 40, 48, 64, 128, 256]
pngs = {}
for s in sizes:
    png_path = os.path.join(tmp, f"ico-{s}.png")
    subprocess.run(["resvg", "-w", str(s), "-h", str(s), svg, png_path], check=True)
    with open(png_path, "rb") as f:
        pngs[s] = f.read()

# Build ICO
out = bytearray(struct.pack('<HHH', 0, 1, len(sizes)))
offset = 6 + 16 * len(sizes)
for s in sizes:
    w = 0 if s == 256 else s
    h = 0 if s == 256 else s
    data = pngs[s]
    out.extend(struct.pack('<BBBBHHII', w, h, 0, 0, 1, 32, len(data), offset))
    offset += len(data)

for s in sizes:
    out.extend(pngs[s])

with open(out_ico, "wb") as f:
    f.write(out)
print(f"Windows icon written: {out_ico} ({len(sizes)} resolutions, {len(out)} bytes)")
PYEOF

# macOS .icns (if iconutil exists).
if command -v iconutil >/dev/null; then
  SET="$TMP/simcraft.iconset"
  mkdir -p "$SET"
  for s in 16 32 128 256 512; do
    render "$MAC" "$s" "$SET/icon_${s}x${s}.png"
    render "$MAC" $((s * 2)) "$SET/icon_${s}x${s}@2x.png"
  done
  iconutil -c icns -o "$DIR/simcraft.icns" "$SET"
  echo "macOS icon bundle written: $DIR/simcraft.icns"
else
  echo "note: iconutil not found (macOS only); simcraft.icns not regenerated" >&2
fi

echo "All icons successfully generated in $DIR"
