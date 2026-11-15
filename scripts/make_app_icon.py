"""햇빛바라기 앱 아이콘: 맑은 한낮 하늘의 햇살 게이지 (빛살 12개 중 8개가 찬 해).

    python3 scripts/make_app_icon.py
아이폰 · 워치 · 웹페이지 아이콘을 한 번에 다시 만든다.
"""
import math
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
S = 4096; C = S / 2
TOP, BOTTOM = (40, 130, 240), (110, 190, 255)     # 한낮 하늘: 짙은 파랑 → 맑은 하늘색
SUN = (255, 214, 40)                               # 해
RAY_ON, RAY_OFF = (255, 214, 40), (255, 255, 255, 90)
RAYS, LIT = 12, 8


def draw() -> Image.Image:
    img = Image.new("RGB", (S, S)); d = ImageDraw.Draw(img)
    for y in range(S):
        t = y / (S - 1)
        d.line([(0, y), (S, y)], fill=tuple(int(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3)))
    d.ellipse([C - 820, C - 820, C + 820, C + 820], fill=SUN)
    off = Image.new("RGBA", (S, S), (0, 0, 0, 0)); do = ImageDraw.Draw(off)
    for k in range(RAYS):
        a = math.radians(-90 + k * 360 / RAYS)
        p1 = (C + math.cos(a) * 1100, C + math.sin(a) * 1100)
        p2 = (C + math.cos(a) * 1650, C + math.sin(a) * 1650)
        if k < LIT:
            d.line([p1, p2], fill=RAY_ON, width=230)
            for x, y in (p1, p2):
                d.ellipse([x - 115, y - 115, x + 115, y + 115], fill=RAY_ON)
        else:
            do.line([p1, p2], fill=RAY_OFF, width=230)
            for x, y in (p1, p2):
                do.ellipse([x - 115, y - 115, x + 115, y + 115], fill=RAY_OFF)
    img.paste(off, (0, 0), off)
    return img.resize((1024, 1024), Image.LANCZOS)


if __name__ == "__main__":
    icon = draw()
    icon.save(ROOT / "SunlightTracker/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
    icon.save(ROOT / "SunlightWatch/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
    icon.resize((256, 256), Image.LANCZOS).save(ROOT / "docs/icon.png")
