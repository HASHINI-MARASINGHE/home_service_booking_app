"""Draws the round HomeCare logo (blue circle, white house, heart) as a PNG.

    python tool/draw_logo_circle.py design/app_icon/homecare_icon_circle_1024.png

The house and heart are the same vector shapes as the logo SVG. Here they are
drawn at 78% of their original size so the house sits comfortably inside the
circle. Needs Pillow and numpy.
"""
import sys

import numpy as np
from PIL import Image, ImageDraw

OUT = sys.argv[1]
SIZE = 1024
SS = 4  # supersampling, for smooth edges
N = SIZE * SS
SCALE = 0.7825  # house size relative to the original 1024 artwork

START = np.array([0x2F, 0x6B, 0xD1], float)
END = np.array([0x0E, 0x2E, 0x6E], float)
HEART_END = np.array([0x14, 0x3C, 0x85], float)


def quad(p0, p1, p2, n=24):
    t = np.linspace(0, 1, n)[:, None]
    return (1 - t) ** 2 * p0 + 2 * (1 - t) * t * p1 + t**2 * p2


def cubic(p0, p1, p2, p3, n=40):
    t = np.linspace(0, 1, n)[:, None]
    return ((1 - t) ** 3 * p0 + 3 * (1 - t) ** 2 * t * p1
            + 3 * (1 - t) * t**2 * p2 + t**3 * p3)


def house():
    P = lambda x, y: np.array([x, y], float)
    pts = [P(512, 215), P(842, 495)]
    pts += list(quad(P(842, 495), P(850, 502), P(850, 512)))
    pts += [P(850, 770)]
    pts += list(quad(P(850, 770), P(850, 810), P(810, 810)))
    pts += [P(214, 810)]
    pts += list(quad(P(214, 810), P(174, 810), P(174, 770)))
    pts += [P(174, 512)]
    pts += list(quad(P(174, 512), P(174, 502), P(182, 495)))
    return np.array(pts)


def heart():
    P = lambda x, y: np.array([x, y], float)
    pts = []
    for seg in [
        (P(512, 690), P(420, 620), P(380, 575), P(380, 525)),
        (P(380, 525), P(380, 485), P(410, 458), P(445, 458)),
        (P(445, 458), P(475, 458), P(497, 474), P(512, 498)),
        (P(512, 498), P(527, 474), P(549, 458), P(579, 458)),
        (P(579, 458), P(614, 458), P(644, 485), P(644, 525)),
        (P(644, 525), P(644, 575), P(604, 620), P(512, 690)),
    ]:
        pts += list(cubic(*seg))
    return np.array(pts)


def to_canvas(points):
    """Original 1024 coordinates -> shrunk about the centre -> supersampled."""
    p = (points - 512) * SCALE + 512
    return [tuple(v) for v in (p * SS)]


def gradient(box, c0, c1):
    """Diagonal gradient (top left -> bottom right) over box = x0, y0, x1, y1."""
    x0, y0, x1, y1 = box
    ys, xs = np.mgrid[0:N, 0:N]
    t = ((xs - x0) * (x1 - x0) + (ys - y0) * (y1 - y0)) / (
        (x1 - x0) ** 2 + (y1 - y0) ** 2
    )
    t = np.clip(t, 0, 1)[..., None]
    return Image.fromarray((c0 + (c1 - c0) * t).astype(np.uint8), 'RGB')


canvas = Image.new('RGBA', (N, N), (0, 0, 0, 0))
bg_mask = Image.new('L', (N, N), 0)
ImageDraw.Draw(bg_mask).ellipse((0, 0, N - 1, N - 1), fill=255)
canvas.paste(gradient((0, 0, N, N), START, END), (0, 0), bg_mask)

draw = ImageDraw.Draw(canvas)
draw.polygon(to_canvas(house()), fill=(255, 255, 255, 255))

heart_mask = Image.new('L', (N, N), 0)
ImageDraw.Draw(heart_mask).polygon(to_canvas(heart()), fill=255)
hx0, hy0 = (np.array([380, 458]) - 512) * SCALE * SS + 512 * SS
hx1, hy1 = (np.array([644, 690]) - 512) * SCALE * SS + 512 * SS
canvas.paste(gradient((hx0, hy0, hx1, hy1), START, HEART_END), (0, 0), heart_mask)

canvas.resize((SIZE, SIZE), Image.LANCZOS).save(OUT, optimize=True)
print('wrote', OUT)
