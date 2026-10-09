#!/usr/bin/env python3
"""마케팅 스크린샷 목업 생성: HTML 생성 → 헤드리스 Chrome 렌더링.

슬라이드마다 layout 이 달라 배치가 다양함:
  hero-bleed  : 헤드라인 상단 중앙 + 정면 대형 폰, 하단 블리드
  left-text   : 좌측 정렬 텍스트 + 오른쪽으로 기운 폰
  text-bottom : 폰 상단 + 텍스트 하단
  flat-rotate : 평면 회전(-5°) 폰, 하단 블리드
  dark        : 다크 배경 반전 + 정면 폰
"""
import subprocess, sys, pathlib

# 햇빛바라기 — 원본: docs/screenshots/raw/ko (iPhone 18 Pro Max 1320x2868) · raw/ko-ipad (iPad Pro 13" 2064x2752)
# 시뮬레이터에 예시 기록(최근 2주의 햇빛 시간 · 기분 · 한마디)을 넣고 찍었다.
# 제출본: marketing/ko/NN-….png (아이폰 1242x2688) · marketing/ko/ipad-NN-….png (아이패드 2064x2752)
import tempfile
ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "docs" / "screenshots" / "raw" / "ko"
SRC_IPAD = ROOT / "docs" / "screenshots" / "raw" / "ko-ipad"
OUT = ROOT / "docs" / "screenshots" / "marketing" / "ko"
WORK = pathlib.Path(tempfile.gettempdir())
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
W, H = 1242, 2688   # 이 계정의 iPhone 제출 규격

SHOTS = [
    ("01-today.png",    "hero-bleed",  "햇빛을 받을수록<br>해바라기가 자라요", "밖에 나가면 밝기를 재서 햇빛 시간을 모아요"),
    ("02-calendar.png", "left-text",   "하루 햇빛과 기분을<br>한눈에", "날짜마다 햇빛 시간, 기분, 한마디를 남겨요"),
    ("03-stats.png",    "text-bottom", "이번 주 햇빛,<br>얼마나 받았을까", "일별 햇빛 시간과 목표 달성을 그래프로"),
    ("04-goal.png",     "flat-rotate", "나에게 맞는<br>하루 목표", "10분부터 120분까지, 알림 시간도 내 마음대로"),
]
IPAD = [
    ("01-today.png",    "햇빛을 받을수록<br>해바라기가 자라요", "밖에 나가면 밝기를 재서 햇빛 시간을 모아요"),
    ("02-calendar.png", "하루 햇빛과 기분을<br>한눈에", "날짜마다 햇빛 시간, 기분, 한마디를 남겨요"),
    ("03-stats.png",    "이번 주 햇빛,<br>얼마나 받았을까", "일별 햇빛 시간과 목표 달성을 그래프로"),
]
IW, IH = 2064, 2752

BASE_CSS = f"""
* {{ margin:0; padding:0; box-sizing:border-box; }}
html,body {{ width:{W}px; height:{H}px; overflow:hidden; }}
body {{ background:#FFF4D6; font-family:-apple-system, "Apple SD Gothic Neo", sans-serif; position:relative; }}
.headline {{ font-size:100px; font-weight:800; color:#3A2A10; letter-spacing:-2px; line-height:1.2; word-break:keep-all; }}
.sub {{ font-size:52px; font-weight:500; color:#8A7556; letter-spacing:-1px; word-break:keep-all; }}
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

HTML = """<!doctype html><html><head><meta charset="utf-8"><style>
{base}{layout}
</style></head><body>{body}</body></html>"""

def main(only=None):
    OUT.mkdir(parents=True, exist_ok=True)
    for fname, layout, headline, sub in SHOTS:
        if only and fname != only:
            continue
        body_tpl = BODY_PHONE_FIRST if layout == "text-bottom" else BODY_TEXT_FIRST
        body = body_tpl.format(headline=headline, sub=sub, img=(SRC / fname).as_uri())
        html_path = WORK / f"sunflower-{fname.replace('.png', '.html')}"
        html_path.write_text(HTML.format(base=BASE_CSS, layout=LAYOUTS[layout], body=body), encoding="utf-8")
        out_png = OUT / fname
        # Chrome 은 다른 창과 겹치면 가끔 실패한다 — 따로 쓰는 프로필로 세 번까지
        for _ in range(3):
            try:
                r = subprocess.run([CHROME, "--headless=new", f"--screenshot={out_png}",
                                    f"--window-size={W},{H}", "--force-device-scale-factor=1",
                                    "--hide-scrollbars", "--disable-gpu", "--virtual-time-budget=3000",
                                    "--allow-file-access-from-files", html_path.as_uri()],
                                   capture_output=True, timeout=120)
            except subprocess.TimeoutExpired:
                continue
            if r.returncode == 0:
                break
        else:
            raise SystemExit(f"Chrome 이 그리지 못했다: {out_png}")
        print(f"rendered {out_png}")

IPAD_HTML = """<!doctype html><html lang="ko"><head><meta charset="utf-8"><style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
html,body {{ width:{W}px; height:{H}px; overflow:hidden; }}
body {{ background:#FFF4D6; font-family:-apple-system, "Apple SD Gothic Neo", sans-serif; position:relative; }}
.glow {{ position:absolute; left:300px; top:1300px; width:1500px; height:1500px; border-radius:50%; filter:blur(170px); background:rgba(255,190,40,.28); }}
.text {{ position:absolute; left:140px; right:140px; top:200px; text-align:center; }}
.headline {{ font-size:150px; font-weight:800; color:#3A2A10; letter-spacing:-0.03em; line-height:1.16; word-break:keep-all; }}
.sub {{ font-size:66px; font-weight:500; color:#8A7556; margin-top:44px; word-break:keep-all; }}
.ipad {{ position:absolute; left:232px; top:1000px; width:1600px; background:#202226; border:5px solid #d8d4cc; padding:40px; border-radius:100px;
  box-shadow: 0 60px 160px rgba(120,80,20,.22); }}
.ipad img {{ width:100%; display:block; border-radius:60px; }}
</style></head><body><div class="glow"></div>
<div class="text"><div class="headline">{headline}</div><div class="sub">{sub}</div></div>
<div class="ipad"><img src="{img}"></div></body></html>"""


def shoot(html_path, out_png, w, h):
    for _ in range(3):
        try:
            r = subprocess.run([CHROME, "--headless=new", f"--screenshot={out_png}", f"--window-size={w},{h}",
                                "--force-device-scale-factor=1", "--hide-scrollbars", "--disable-gpu",
                                "--virtual-time-budget=3000", "--allow-file-access-from-files", html_path.as_uri()],
                               capture_output=True, timeout=120)
        except subprocess.TimeoutExpired:
            continue
        if r.returncode == 0:
            return
    raise SystemExit(f"Chrome 이 그리지 못했다: {out_png}")


def main_ipad():
    for fname, headline, sub in IPAD:
        html_path = WORK / f"sunflower-ipad-{fname.replace('.png', '.html')}"
        html_path.write_text(IPAD_HTML.format(W=IW, H=IH, headline=headline, sub=sub,
                                              img=(SRC_IPAD / fname).as_uri()), encoding="utf-8")
        out_png = OUT / f"ipad-{fname}"
        shoot(html_path, out_png, IW, IH)
        print(f"rendered {out_png}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
    main_ipad()
