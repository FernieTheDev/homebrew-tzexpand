"""Generate TZExpand app icon at 1024x1024.

Design: macOS-style squircle with indigo→teal gradient, white clock face,
two overlapping hour/minute hand pairs (one solid, one ghosted) to suggest
"the same moment in two timezones".
"""
from PIL import Image, ImageDraw, ImageFilter
import math
import os
import sys

OUT = sys.argv[1]
SIZE = 1024


def squircle_mask(size: int, radius_frac: float = 0.225) -> Image.Image:
    """macOS-style rounded rectangle (continuous corners approximated)."""
    img = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(img)
    r = int(size * radius_frac)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=r, fill=255)
    return img


def vertical_gradient(size: int, top, bottom) -> Image.Image:
    img = Image.new("RGB", (size, size), top)
    px = img.load()
    for y in range(size):
        t = y / (size - 1)
        r = int(top[0] * (1 - t) + bottom[0] * t)
        g = int(top[1] * (1 - t) + bottom[1] * t)
        b = int(top[2] * (1 - t) + bottom[2] * t)
        for x in range(size):
            px[x, y] = (r, g, b)
    return img


def build():
    bg_top = (0x35, 0x3D, 0xD4)     # deep indigo
    bg_bot = (0x12, 0xB5, 0xCB)     # teal
    base = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    grad = vertical_gradient(SIZE, bg_top, bg_bot).convert("RGBA")
    mask = squircle_mask(SIZE)
    base.paste(grad, (0, 0), mask)

    d = ImageDraw.Draw(base)
    cx, cy = SIZE // 2, SIZE // 2

    # Outer ring (clock face white).
    face_r = int(SIZE * 0.34)
    d.ellipse([cx - face_r, cy - face_r, cx + face_r, cy + face_r],
              fill=(255, 255, 255, 255))

    # Hour ticks (12 ticks, 3/6/9/12 stronger).
    inner = face_r * 0.78
    outer = face_r * 0.95
    for i in range(12):
        a = math.radians(i * 30 - 90)
        x1 = cx + math.cos(a) * inner
        y1 = cy + math.sin(a) * inner
        x2 = cx + math.cos(a) * outer
        y2 = cy + math.sin(a) * outer
        cardinal = i % 3 == 0
        w = 14 if cardinal else 6
        col = (0x35, 0x3D, 0xD4, 255) if cardinal else (0x6B, 0x73, 0xB8, 220)
        d.line([(x1, y1), (x2, y2)], fill=col, width=w)

    def hand(angle_deg, length_frac, width, color, butt_back=0.10):
        a = math.radians(angle_deg - 90)
        x_tip = cx + math.cos(a) * face_r * length_frac
        y_tip = cy + math.sin(a) * face_r * length_frac
        x_back = cx - math.cos(a) * face_r * butt_back
        y_back = cy - math.sin(a) * face_r * butt_back
        d.line([(x_back, y_back), (x_tip, y_tip)], fill=color, width=width)

    def clock_angles(hour, minute):
        return (hour * 30 + minute * 0.5, minute * 6)

    # Primary hands: 10:10 (classic clock look), solid indigo.
    indigo = (0x35, 0x3D, 0xD4, 255)
    h_ang, m_ang = clock_angles(10, 10)
    hand(angle_deg=h_ang, length_frac=0.55, width=34, color=indigo)
    hand(angle_deg=m_ang, length_frac=0.78, width=22, color=indigo)

    # Ghost "other timezone" hands: 1:25 (clearly different position), teal.
    teal = (0x12, 0xB5, 0xCB, 220)
    h2, m2 = clock_angles(1, 25)
    hand(angle_deg=h2, length_frac=0.55, width=28, color=teal)
    hand(angle_deg=m2, length_frac=0.78, width=18, color=teal)

    # Center pin.
    pin = 18
    d.ellipse([cx - pin, cy - pin, cx + pin, cy + pin], fill=indigo)

    # Subtle highlight gloss on top half.
    gloss = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    gd = ImageDraw.Draw(gloss)
    gd.ellipse([-SIZE * 0.2, -SIZE * 0.85, SIZE * 1.2, SIZE * 0.55],
               fill=(255, 255, 255, 38))
    gloss = Image.composite(gloss, Image.new("RGBA", gloss.size), mask)
    base = Image.alpha_composite(base, gloss)

    base.save(OUT)


if __name__ == "__main__":
    build()
    print(f"wrote {OUT}")
