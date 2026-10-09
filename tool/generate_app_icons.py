"""Builds every app icon from the round HomeCare logo.

    python tool/generate_app_icons.py design/app_icon/homecare_icon_circle_1024.png

The logo is a 1024 x 1024 PNG: a blue circle on a transparent background, with
the white house and heart inside. (tool/draw_logo_circle.py draws it.)

Writes the Android launcher icons (classic round and adaptive), the iOS icon
set and the web icons. Needs Pillow and numpy. Run it again whenever the logo
changes.
"""
import os
import sys

import numpy as np
from PIL import Image

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
logo = Image.open(sys.argv[1]).convert('RGBA')
assert logo.size == (1024, 1024), 'The logo must be 1024 x 1024.'

START = np.array([0x2F, 0x6B, 0xD1], float)
END = np.array([0x0E, 0x2E, 0x6E], float)


def save(img, rel, size):
    path = os.path.join(root, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(path, optimize=True)


# The white house with the heart cut out, on transparent. Its alpha is how
# white each pixel of the logo is, so a gradient behind it shows through the
# heart exactly as in the logo.
on_black = Image.new('RGBA', logo.size, (0, 0, 0, 255))
on_black.alpha_composite(logo)
red = on_black.getchannel('R').point(
    lambda v: 0 if v <= 120 else 255 if v >= 200 else int((v - 120) * 255 / 80)
)
glyph = Image.new('RGBA', logo.size, (255, 255, 255, 0))
glyph.putalpha(red)


def gradient_square(size=1024):
    ys, xs = np.mgrid[0:size, 0:size]
    t = ((xs + ys) / (2 * (size - 1)))[..., None]
    rgb = (START + (END - START) * t).astype(np.uint8)
    return Image.fromarray(rgb, 'RGB').convert('RGBA')


def square_icon(zoom=1.15):
    """Full-bleed square (iOS and maskable web icons must have no
    transparency): the gradient with the house a little larger than in the
    round logo, because a square has more room."""
    sq = gradient_square()
    g = glyph.resize((int(1024 * zoom), int(1024 * zoom)), Image.LANCZOS)
    off = (1024 - g.width) // 2
    sq.alpha_composite(g, (off, off))
    return sq


# ------------------------------------------------------------------ Android
res = 'android/app/src/main/res'
for dpi, px in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
    save(logo, f'{res}/mipmap-{dpi}/ic_launcher.png', px)

# Adaptive icon (Android 8+): the phone applies its own shape (a circle here)
# to a gradient background plus this foreground. The house stays well inside
# the 66% safe zone.
for dpi, px in {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}.items():
    save(glyph, f'{res}/mipmap-{dpi}/ic_launcher_foreground.png', px)

# ---------------------------------------------------------------------- iOS
square = square_icon()
ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
ios_sizes = {
    'Icon-App-20x20@1x.png': 20, 'Icon-App-20x20@2x.png': 40, 'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29, 'Icon-App-29x29@2x.png': 58, 'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40, 'Icon-App-40x40@2x.png': 80, 'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120, 'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76, 'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167, 'Icon-App-1024x1024@1x.png': 1024,
}
for name, px in ios_sizes.items():
    if os.path.exists(os.path.join(root, ios, name)):
        save(square.convert('RGB'), f'{ios}/{name}', px)

# ---------------------------------------------------------------------- web
save(logo, 'web/favicon.png', 32)
save(logo, 'web/icons/Icon-192.png', 192)
save(logo, 'web/icons/Icon-512.png', 512)
save(square, 'web/icons/Icon-maskable-192.png', 192)
save(square, 'web/icons/Icon-maskable-512.png', 512)

print('icons written')
