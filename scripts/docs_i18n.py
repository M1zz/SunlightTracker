#!/usr/bin/env python3
"""docs/ 의 언어별 페이지(index · privacy · support)에 hreflang 과 언어 전환 링크를 채운다.

루트(docs/*.html)는 한국어, docs/<언어>/*.html 은 그 언어. 다시 돌려도 같은 결과가 나온다.
사용법: python3 scripts/docs_i18n.py
"""
import pathlib, re

DOCS = pathlib.Path(__file__).resolve().parent.parent / "docs"
BASE = "https://m1zz.github.io/SunlightTracker/"
LANGS = [("ko", "한국어"), ("en", "English"), ("zh-Hans", "简体中文"), ("zh-Hant", "繁體中文"), ("ja", "日本語"),
         ("ru", "Русский"), ("es", "Español"), ("de", "Deutsch"), ("fr", "Français"), ("it", "Italiano"),
         ("pt-BR", "Português (Brasil)"), ("th", "ไทย"), ("vi", "Tiếng Việt"), ("cs", "Čeština"), ("da", "Dansk"),
         ("el", "Ελληνικά"), ("fi", "Suomi"), ("id", "Bahasa Indonesia"), ("nb", "Norsk bokmål"), ("nl", "Nederlands"),
         ("pl", "Polski"), ("sv", "Svenska"), ("tr", "Türkçe")]
PAGES = ["index.html", "privacy.html", "support.html"]


def url(lang, page):
    path = "" if page == "index.html" else page
    return BASE + path if lang == "ko" else f"{BASE}{lang}/{path}"


def rel(src, dst, page):
    """src 언어 페이지에서 dst 언어 같은 페이지로 가는 상대 경로."""
    up = "" if src == "ko" else "../"
    return f"{up}{page}" if dst == "ko" else f"{up}{dst}/{page}"


def block(tag, inner):
    return f"<!--{tag}-->{inner}<!--/{tag}-->"


for lang, _ in LANGS:
    for page in PAGES:
        f = DOCS / page if lang == "ko" else DOCS / lang / page
        s = f.read_text(encoding="utf-8")
        hre = "\n" + "".join(f'  <link rel="alternate" hreflang="{l}" href="{url(l, page)}">\n' for l, _ in LANGS)
        hre += f'  <link rel="alternate" hreflang="x-default" href="{url("ko", page)}">\n  '
        links = " · ".join(
            f'<a href="{rel(lang, l, page)}" hreflang="{l}" lang="{l}"' + (' aria-current="page"' if l == lang else "") + f">{name}</a>"
            for l, name in LANGS)
        sw = f'\n    <nav class="langs">{links}</nav>\n    '
        for tag, inner in (("HREFLANG", hre), ("LANGSWITCH", sw)):
            s, n = re.subn(rf"<!--{tag}-->(.*?<!--/{tag}-->)?", lambda m: block(tag, inner), s, flags=re.S)
            if n != 1:
                raise SystemExit(f"{f}: <!--{tag}--> 자리가 {n}개")
        f.write_text(s, encoding="utf-8")
print("ok")
