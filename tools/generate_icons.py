#!/usr/bin/env python3
"""Menghasilkan aset launcher icon Android dari mujib_logo.png.

Rasio aspek logo dipertahankan (tidak diregangkan/dipotong): logo hanya
di-crop ke bounding box piksel non-transparan, lalu diskalakan proporsional.

Pemakaian (dari root repository):
    python3 tools/generate_icons.py
"""
from pathlib import Path
from shutil import copyfile

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "mujib_logo.png"
RES = ROOT / "android/app/src/main/res"
BG = (11, 11, 13, 255)  # charcoal #0B0B0D

DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}


def load_logo() -> Image.Image:
    im = Image.open(SRC).convert("RGBA")
    bbox = im.getchannel("A").getbbox()
    if bbox is None:
        raise SystemExit("Logo tidak memiliki piksel terlihat")
    return im.crop(bbox)


def fit_width(logo: Image.Image, width: int) -> Image.Image:
    height = round(logo.height * width / logo.width)
    return logo.resize((width, height), Image.LANCZOS)


def centered(canvas: Image.Image, layer: Image.Image) -> None:
    x = (canvas.width - layer.width) // 2
    y = (canvas.height - layer.height) // 2
    canvas.alpha_composite(layer, (x, y))


def monochrome(layer: Image.Image) -> Image.Image:
    alpha = layer.getchannel("A")
    white = Image.new("RGBA", layer.size, (255, 255, 255, 0))
    white.putalpha(alpha)
    return white


def main() -> None:
    logo = load_logo()
    print(f"Logo crop: {logo.size}")

    # Aset Flutter (salinan persis, tanpa modifikasi).
    assets = ROOT / "assets/images"
    assets.mkdir(parents=True, exist_ok=True)
    copyfile(SRC, assets / "mujib_logo.png")

    for name, scale in DENSITIES.items():
        # Adaptive icon: kanvas 108dp, area aman 66dp di tengah.
        s = round(108 * scale)
        fg = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        layer = fit_width(logo, round(s * 0.54))
        centered(fg, layer)
        d = RES / f"drawable-{name}"
        d.mkdir(parents=True, exist_ok=True)
        fg.save(d / "ic_launcher_foreground.png", optimize=True)

        mono = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        centered(mono, monochrome(layer))
        mono.save(d / "ic_launcher_monochrome.png", optimize=True)

        # Ikon legacy (API < 26): 48dp.
        px = round(48 * scale)
        m = RES / f"mipmap-{name}"
        m.mkdir(parents=True, exist_ok=True)

        sq = Image.new("RGBA", (px, px), (0, 0, 0, 0))
        mask = Image.new("L", (px, px), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, px - 1, px - 1), radius=round(px * 0.22), fill=255)
        plate = Image.new("RGBA", (px, px), BG)
        sq.paste(plate, (0, 0), mask)
        centered(sq, fit_width(logo, round(px * 0.70)))
        sq.save(m / "ic_launcher.png", optimize=True)

        rd = Image.new("RGBA", (px, px), (0, 0, 0, 0))
        cmask = Image.new("L", (px, px), 0)
        ImageDraw.Draw(cmask).ellipse((0, 0, px - 1, px - 1), fill=255)
        rd.paste(plate, (0, 0), cmask)
        centered(rd, fit_width(logo, round(px * 0.60)))
        rd.save(m / "ic_launcher_round.png", optimize=True)

    print("Selesai: ikon launcher dibuat di", RES)


if __name__ == "__main__":
    main()
