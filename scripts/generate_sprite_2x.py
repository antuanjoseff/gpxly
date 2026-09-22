"""Genera sprite@2x.png / sprite@2x.json a partir de sprite.png / sprite.json.

MapLibre Native demana automàticament les variants @2x quan el dispositiu té
pixelRatio > 1. Si no existeixen, la càrrega de l'sprite falla silenciosament
i les icones no es dibuixen mai en mode offline.
"""

import json
from pathlib import Path

from PIL import Image

SPRITES_DIR = Path(__file__).resolve().parent.parent / "assets" / "sprites"

png_path = SPRITES_DIR / "sprite.png"
json_path = SPRITES_DIR / "sprite.json"

img = Image.open(png_path)
img_2x = img.resize((img.width * 2, img.height * 2), Image.LANCZOS)
img_2x.save(SPRITES_DIR / "sprite@2x.png")

data = json.loads(json_path.read_text(encoding="utf-8"))
data_2x = {
    name: {
        "width": info["width"] * 2,
        "height": info["height"] * 2,
        "x": info["x"] * 2,
        "y": info["y"] * 2,
        "pixelRatio": 2,
    }
    for name, info in data.items()
}
(SPRITES_DIR / "sprite@2x.json").write_text(
    json.dumps(data_2x, indent=2), encoding="utf-8"
)

print("sprite@2x.png:", img_2x.size)
print("sprite@2x.json entries:", len(data_2x))
