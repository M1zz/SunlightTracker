#!/usr/bin/env python3
"""App Store 크리에이티브 자산(제품 페이지 헤더 · 검색 결과) 생성: HTML → 헤드리스 Chrome.

사용법: python3 scripts/make_creative_assets.py [언어 ...]     (없으면 전부)

자리
  docs/screenshots/creative/<스토어 로케일>/header.png   3840x1646  제품 페이지 맨 위
  docs/screenshots/creative/<스토어 로케일>/search.png   3840x2560  검색 결과 (없으면 스크린샷이 대신 보인다)

기기 화면 재료: docs/screenshots/raw/creative/<언어>/
  01-today.png    오늘 화면 (해바라기 · 오늘의 햇빛 · 모은 햇빛)
  02-records.png  기록 캘린더 (날짜별 기분과 햇빛 분)
  시뮬레이터(iPhone 17 Pro Max)에서 예시 기록을 넣고 찍은 것이다.

⚠️ 안전 영역 밖은 기기에 따라 잘린다. 글은 **반드시** 안전 영역 안에 둔다(배경 · 기기 그림은 넘쳐도 된다).
   수치는 Apple 공식 PSD 템플릿에서 잰 값이다(https://developer.apple.com/app-store/asset-best-practices/).
   아이폰에서 헤더는 가운데만 남고, 검색 결과는 약 385pt 폭으로 줄어 보인다. 그래서 글이 크다.

⚠️ 가격 · 할인 · 주소(URL) · 수상 · 다른 플랫폼 이름은 넣지 않는다(Apple 가이드).
"""
import subprocess, sys, pathlib, tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw" / "creative"
OUT = ROOT / "docs" / "screenshots" / "creative"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# 앱 언어 코드 → App Store Connect 로케일. 스토어에는 한국어만 있다.
STORE = {}

# (가로, 세로, 안전 영역 left, top, right, bottom)
SPEC = {
    "header": (3840, 1646, (1097, 493, 2743, 1154)),
    "search": (3840, 2560, (836, 765, 3004, 1795)),
}

# 검색 결과: 눈썹글(그 나라 검색어) · 헤드라인 · 보조 한 줄. 기기 화면(오늘 화면)과 같은 이야기다.
SEARCH = {
    "ko": ("햇빛 산책 기록", "오늘 받은 햇빛,<br>알아서 기록", "밖에 나가 햇빛을 쬐면 하루 목표까지 채워져요"),
}

# 헤더는 처음 온 사람에게 한 가지 약속만 한다: 햇빛을 모아 나의 해바라기를 키운다.
HEADER = {
    "ko": ("하루 한 줌의 햇빛", "햇빛을 모아<br>해바라기를 키워요"),
}

# 바탕은 앱 아이콘의 하늘색 → 살구빛 그라데이션과 앱의 주황(.tint(.orange))을 따른다.
BASE_CSS = """
* { margin:0; padding:0; box-sizing:border-box; }
html,body { width:%(W)dpx; height:%(H)dpx; overflow:hidden; }
body { background:linear-gradient(155deg, #c9ecfa 0%%, #fff3dc 52%%, #ffcfb4 100%%); position:relative;
  font-family:-apple-system, "SF Pro Display", "Apple SD Gothic Neo", sans-serif; }
.glow { position:absolute; border-radius:50%%; filter:blur(160px); pointer-events:none; }
.sun { position:absolute; border-radius:50%%;
  background:radial-gradient(circle, #fffbe8 0%%, #ffe36e 38%%, rgba(255,200,60,.55) 52%%, rgba(255,190,60,0) 72%%); }
.spark { position:absolute; width:22px; height:22px; border-radius:50%%; background:#fff;
  box-shadow:0 0 30px 12px rgba(255,255,255,.75); }
.text { position:absolute; display:flex; flex-direction:column; justify-content:center; }
.eyebrow { font-weight:700; color:#ee7300; letter-spacing:-0.01em; line-height:1.15; }
.headline { font-weight:800; color:#3a240f; letter-spacing:-0.03em; line-height:1.14; text-wrap:balance; }
.sub { font-weight:500; color:#80634a; letter-spacing:-0.01em; line-height:1.35; text-wrap:balance; }
:lang(ko) .headline, :lang(ko) .sub, :lang(ko) .eyebrow { word-break:keep-all; }
.phone { position:absolute; background:#1b1b1d; border:6px solid #4a4a4e; padding:40px; border-radius:190px;
  box-shadow: 0 60px 160px rgba(120,60,10,.30), 0 0 0 2px #2a2a2d inset; }
.phone img { width:100%%; display:block; border-radius:152px; }
"""

# 글이 상자를 넘지 않을 때까지 줄인다. 잘리는 글은 없다 - 끝까지 안 맞으면 표시하고 멈춘다.
FIT_JS = """
<script>
// 문구에 적은 줄(<br>)보다 더 쪼개지면 "Rispondi / con un / tocco" 처럼 읽기가 끊긴다.
// 적은 줄 수를 지킬 때까지 줄인다.
function lines(el) {
  return Math.round(el.getBoundingClientRect().height / parseFloat(getComputedStyle(el).lineHeight));
}
function fit(box, el, max, min) {
  const want = el.querySelectorAll('br').length + 1;
  let size = max;
  el.style.fontSize = size + 'px';
  while (size > min && (box.scrollHeight > box.clientHeight + 1 || box.scrollWidth > box.clientWidth + 1 ||
         lines(el) > want)) {
    size -= 4; el.style.fontSize = size + 'px';
  }
  if (box.scrollHeight > box.clientHeight + 1 || box.scrollWidth > box.clientWidth + 1 || lines(el) > want)
    document.body.dataset.overflow = '1';
}
document.fonts.ready.then(() => {
  const box = document.querySelector('.text');
  const h = document.querySelector('.headline');
  fit(box, h, +h.dataset.max, +h.dataset.min);
  document.body.dataset.done = '1';
});
</script>
"""


def phone(img, left, top, width, rotate=0):
    return (f'<div class="phone" style="left:{left}px;top:{top}px;width:{width}px;'
            f'transform:rotate({rotate}deg)"><img src="{img}"></div>')


def sparks(points):
    """아이콘의 반짝임. 장식이라 잘려도 된다."""
    return "".join(f'<div class="spark" style="left:{x}px;top:{y}px;transform:scale({k})"></div>' for x, y, k in points)


def search_html(lang):
    W, H, (l, t, r, b) = SPEC["search"]
    eyebrow, headline, sub = SEARCH[lang]
    sw, sh = r - l, b - t
    col = int(sw * 0.56)
    # 기기는 안전 영역 오른쪽 몫에 서서, 위아래로 넘쳐 화면 밖까지 이어진다(기기 그림은 잘려도 된다).
    ph_w = 1040
    ph_left = l + col + int(sw * 0.04)
    img = (RAW / lang / "01-today.png").as_uri()
    return f"""
<div class="sun" style="left:2700px;top:-900px;width:2000px;height:2000px"></div>
<div class="glow" style="left:{l - 700}px;top:{t - 300}px;width:1600px;height:1200px;background:rgba(255,255,255,.45)"></div>
{sparks([(300, 420, 1.4), (620, 2050, 1.0), (2380, 2250, 1.2), (3600, 1500, 1.6), (180, 1500, 0.9)])}
{phone(img, ph_left, t - 360, ph_w, 0)}
<div class="text" style="left:{l}px;top:{t}px;width:{col}px;height:{sh}px">
  <div class="eyebrow" style="font-size:96px">{eyebrow}</div>
  <div class="headline" data-max="250" data-min="140" style="margin-top:36px">{headline}</div>
  <div class="sub" style="font-size:84px;margin-top:52px">{sub}</div>
</div>"""


def header_html(lang):
    W, H, (l, t, r, b) = SPEC["header"]
    eyebrow, headline = HEADER[lang]
    sw, sh = r - l, b - t
    left_img = (RAW / lang / "01-today.png").as_uri()
    right_img = (RAW / lang / "02-records.png").as_uri()
    return f"""
<div class="sun" style="left:2950px;top:-950px;width:1700px;height:1700px"></div>
<div class="glow" style="left:{l - 200}px;top:{t - 300}px;width:{sw + 400}px;height:{sh + 600}px;background:rgba(255,255,255,.5)"></div>
{sparks([(120, 160, 1.2), (1000, 1420, 0.9), (2700, 160, 1.0), (3700, 1300, 1.4), (1980, 1480, 0.8)])}
{phone(left_img, 300, 360, 640, -9)}
{phone(right_img, 2900, 360, 640, 9)}
<div class="text" style="left:{l}px;top:{t}px;width:{sw}px;height:{sh}px;align-items:center;text-align:center">
  <div class="eyebrow" style="font-size:76px">{eyebrow}</div>
  <div class="headline" data-max="210" data-min="110" style="margin-top:22px">{headline}</div>
</div>"""


def render(lang, kind):
    W, H, _ = SPEC[kind]
    body = search_html(lang) if kind == "search" else header_html(lang)
    page = (f'<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>'
            f'{BASE_CSS % {"W": W, "H": H}}</style></head><body>{body}{FIT_JS}</body></html>')
    html_path = pathlib.Path(tempfile.gettempdir()) / f"sunflower-creative-{lang}-{kind}.html"
    html_path.write_text(page, encoding="utf-8")
    # 글이 끝까지 안 맞으면 그림을 만들지 않는다(잘린 글이 스토어에 올라가는 것보다 낫다).
    dom = subprocess.run([CHROME, "--headless=new", "--dump-dom", f"--window-size={W},{H}",
                          "--force-device-scale-factor=1", "--disable-gpu", "--virtual-time-budget=3000",
                          html_path.as_uri()], capture_output=True, text=True, timeout=90).stdout
    if 'data-done="1"' not in dom:
        raise SystemExit(f"글 맞추기가 끝나지 않았다: {lang} {kind}")
    if 'data-overflow="1"' in dom:
        raise SystemExit(f"글이 안전 영역을 넘는다: {lang} {kind} - 문구를 줄일 것")
    out_dir = OUT / STORE.get(lang, lang)
    out_dir.mkdir(parents=True, exist_ok=True)
    out_png = out_dir / f"{kind}.png"
    # ⚠️ Chrome 은 가끔 아무것도 안 그리고 끝나거나 멈춘다. 세 번까지 한다.
    for _ in range(3):
        try:
            r = subprocess.run([CHROME, "--headless=new", f"--screenshot={out_png}",
                                f"--window-size={W},{H}", "--force-device-scale-factor=1",
                                "--hide-scrollbars", "--disable-gpu", "--virtual-time-budget=3000",
                                "--allow-file-access-from-files", html_path.as_uri()],
                               capture_output=True, timeout=90)
        except subprocess.TimeoutExpired:
            continue
        if r.returncode == 0:
            break
    else:
        raise SystemExit(f"Chrome 이 그리지 못했다: {out_png}")
    print(f"rendered {out_png}")


if __name__ == "__main__":
    langs = sys.argv[1:] or list(SEARCH)
    for lang in langs:
        if lang not in SEARCH:
            raise SystemExit(f"모르는 언어: {lang} (아는 것: {', '.join(SEARCH)})")
        for kind in ("header", "search"):
            render(lang, kind)
