#!/usr/bin/env python3
"""마케팅 스크린샷 목업 생성: HTML 생성 → 헤드리스 Chrome 렌더링.

슬라이드마다 layout 이 달라 배치가 다양함:
  hero-bleed  : 헤드라인 상단 중앙 + 정면 대형 폰, 하단 블리드
  left-text   : 좌측 정렬 텍스트 + 오른쪽으로 기운 폰
  text-bottom : 폰 상단 + 텍스트 하단
  flat-rotate : 평면 회전(-5°) 폰, 하단 블리드
  dark        : 다크 배경 반전 + 정면 폰
"""
import subprocess, sys, pathlib, time

# 햇빛바라기 — 원본: docs/screenshots/raw/ko (iPhone 18 Pro Max 1320x2868) · raw/ko-ipad (iPad Pro 13" 2064x2752)
# 시뮬레이터에 예시 기록(최근 2주의 햇빛 시간 · 기분 · 한마디)을 넣고 찍었다.
# 제출본: marketing/ko/NN-….png (아이폰 1242x2688) · marketing/ko/ipad-NN-….png (아이패드 2064x2752)
# 다른 언어: raw/<로케일>/ · raw/<로케일>-ipad/ → marketing/<로케일>/. 문구는 screenshot_copy.py.
# 사용법: python3 scripts/make_marketing_screenshots.py [로케일 ...]   (없으면 전부)
import tempfile
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from screenshot_copy import MARKETING, font_stack
ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw"
MKT = ROOT / "docs" / "screenshots" / "marketing"
WORK = pathlib.Path(tempfile.gettempdir())
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
W, H = 1242, 2688   # 이 계정의 iPhone 제출 규격

FILES = [("01-today.png", "hero-bleed"), ("02-calendar.png", "left-text"),
         ("03-stats.png", "text-bottom"), ("04-goal.png", "flat-rotate")]
IPAD_FILES = ["01-today.png", "02-calendar.png", "03-stats.png"]
IW, IH = 2064, 2752

BASE_CSS = f"""
* {{ margin:0; padding:0; box-sizing:border-box; }}
html,body {{ width:{W}px; height:{H}px; overflow:hidden; }}
body {{ background:#FFF4D6; font-family:{{FONT}}; position:relative; }}
.headline {{ font-size:100px; font-weight:800; color:#3A2A10; letter-spacing:-2px; line-height:1.2; word-break:keep-all; }}
.sub {{ font-size:52px; font-weight:500; color:#8A7556; letter-spacing:-1px; word-break:keep-all; padding:0 60px; text-wrap:balance; }}
.phone {{ background:#17171a; border-radius:116px; border:3px solid #3a3a3e; padding:25px;
  box-shadow: 60px 90px 120px rgba(0,0,0,.28), 20px 30px 50px rgba(0,0,0,.18); }}
.phone img {{ width:100%; display:block; border-radius:92px; }}
"""

LAYOUTS = {
    # 1) 정면 대형, 하단 블리드
    "hero-bleed": """
.headline { text-align:center; margin-top:290px; padding:0 70px; }
.sub { text-align:center; margin-top:52px; }
.wrap { display:flex; justify-content:center; margin-top:150px; }
.phone { width:1000px; }
""",
    # 2) 좌측 정렬 텍스트 + 오른쪽 기울기, 오른쪽 블리드
    "left-text": """
.headline { text-align:left; margin:300px 0 0 110px; }
.sub { text-align:left; margin:48px 0 0 114px; }
.wrap { perspective:2600px; perspective-origin:30% 30%; position:absolute; left:300px; top:990px; }
.phone { width:840px; transform:rotateY(16deg) rotateX(2deg); }
""",
    # 3) 폰 상단, 텍스트 하단
    "text-bottom": """
.wrap { perspective:2800px; perspective-origin:50% 40%; display:flex; justify-content:center; margin-top:170px; }
.phone { width:880px; transform:rotateY(-10deg) rotateX(2deg); }
.headline { text-align:center; margin-top:120px; padding:0 70px; }
.sub { text-align:center; margin-top:48px; }
""",
    # 4) 평면 회전, 좌측 치우침 + 하단 블리드
    "flat-rotate": """
.headline { text-align:center; margin-top:270px; padding:0 70px; }
.sub { text-align:center; margin-top:52px; }
.wrap { position:absolute; left:120px; top:1010px; }
.phone { width:1010px; transform:rotate(-6deg); }
""",
    # 5) 다크 배경 반전 + 정면
    "dark": """
body { background:#131316; }
.headline { color:#f5f5f7; text-align:center; margin-top:290px; padding:0 70px; }
.sub { color:#77777d; text-align:center; margin-top:52px; }
.wrap { display:flex; justify-content:center; margin-top:150px; }
.phone { width:930px; border-color:#48484e;
  box-shadow: 0 0 160px rgba(80,140,255,.22), 40px 70px 110px rgba(0,0,0,.55); }
""",
}

# text-bottom 은 폰이 먼저 오는 DOM 순서
BODY_TEXT_FIRST = '<div class="headline">{headline}</div><div class="sub">{sub}</div><div class="wrap"><div class="phone"><img src="{img}"></div></div>'
BODY_PHONE_FIRST = '<div class="wrap"><div class="phone"><img src="{img}"></div></div><div class="headline">{headline}</div><div class="sub">{sub}</div>'

HTML = """<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>
{base}{layout}
</style></head><body>{body}</body></html>"""

def main(lang):
    out = MKT / lang
    out.mkdir(parents=True, exist_ok=True)
    for (fname, layout), (headline, sub) in zip(FILES, MARKETING[lang]):
        body_tpl = BODY_PHONE_FIRST if layout == "text-bottom" else BODY_TEXT_FIRST
        body = body_tpl.format(headline=headline, sub=sub, img=(RAW / lang / fname).as_uri())
        html_path = WORK / f"sunflower-{lang}-{fname.replace('.png', '.html')}"
        base = BASE_CSS.replace("{FONT}", font_stack(lang))
        html_path.write_text(HTML.format(lang=lang, base=base, layout=LAYOUTS[layout], body=body), encoding="utf-8")
        out_png = out / fname
        shoot(html_path, out_png, W, H)
        print(f"rendered {out_png}")

IPAD_HTML = """<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
html,body {{ width:{W}px; height:{H}px; overflow:hidden; }}
body {{ background:#FFF4D6; font-family:{font}; position:relative; }}
.glow {{ position:absolute; left:300px; top:1300px; width:1500px; height:1500px; border-radius:50%; filter:blur(170px); background:rgba(255,190,40,.28); }}
.text {{ position:absolute; left:140px; right:140px; top:200px; text-align:center; }}
.headline {{ font-size:150px; font-weight:800; color:#3A2A10; letter-spacing:-0.03em; line-height:1.16; word-break:keep-all; }}
.sub {{ font-size:66px; font-weight:500; color:#8A7556; margin-top:44px; word-break:keep-all; text-wrap:balance; }}
.ipad {{ position:absolute; left:232px; top:1000px; width:1600px; background:#202226; border:5px solid #d8d4cc; padding:40px; border-radius:100px;
  box-shadow: 0 60px 160px rgba(120,80,20,.22); }}
.ipad img {{ width:100%; display:block; border-radius:60px; }}
</style></head><body><div class="glow"></div>
<div class="text"><div class="headline">{headline}</div><div class="sub">{sub}</div></div>
<div class="ipad"><img src="{img}"></div></body></html>"""


def shoot(html_path, out_png, w, h):
    for _ in range(4):
        started = time.time()
        try:
            r = subprocess.run([CHROME, "--headless=new", f"--user-data-dir={tempfile.mkdtemp(prefix='sunflower-chrome-')}", f"--screenshot={out_png}", f"--window-size={w},{h}",
                                "--force-device-scale-factor=1", "--hide-scrollbars", "--disable-gpu",
                                "--virtual-time-budget=3000", "--allow-file-access-from-files", html_path.as_uri()],
                               capture_output=True, timeout=150)
        except subprocess.TimeoutExpired:
            continue
        # 다 그린 뒤 정리 단계에서 죽어도(Teardown watchdog) 그림은 이미 저장돼 있다 — 파일로 판단한다.
        if r.returncode == 0 or (out_png.exists() and out_png.stat().st_mtime >= started - 1 and out_png.stat().st_size > 0):
            return
    raise SystemExit(f"Chrome 이 그리지 못했다: {out_png}")


def main_ipad(lang):
    for fname, (headline, sub) in zip(IPAD_FILES, MARKETING[lang]):
        html_path = WORK / f"sunflower-ipad-{lang}-{fname.replace('.png', '.html')}"
        html_path.write_text(IPAD_HTML.format(W=IW, H=IH, lang=lang, font=font_stack(lang), headline=headline, sub=sub,
                                              img=(RAW / f"{lang}-ipad" / fname).as_uri()), encoding="utf-8")
        out_png = MKT / lang / f"ipad-{fname}"
        shoot(html_path, out_png, IW, IH)
        print(f"rendered {out_png}")


if __name__ == "__main__":
    for lang in sys.argv[1:] or list(MARKETING):
        if lang not in MARKETING:
            raise SystemExit(f"모르는 언어: {lang}")
        main(lang)
        main_ipad(lang)
