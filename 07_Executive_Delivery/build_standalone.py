#!/usr/bin/env python3
"""
Bundle the exported .dc.html dashboard into one self-contained HTML file.

The export loads its React runtime from unpkg and its typefaces from Google
Fonts. Neither is reachable under an Artifact's content-security policy, and
both are a broken-page risk anywhere offline, so both get inlined here.

Babel is deliberately NOT inlined: support.js only pulls it in for `jsx`
scripts, and this dashboard's script block is plain JS. loadReactUmd() and
ensureBabel() both short-circuit on pre-existing globals, so inlining the two
React UMD bundles ahead of support.js is enough to stop every network call.

Fetch the dependencies first (they are not vendored into the repo):

    npm install --no-save --prefix ./vendnpm react@18.3.1 react-dom@18.3.1
    npm install --no-save --prefix ./fonts \
        @fontsource/newsreader@5 @fontsource/ibm-plex-sans@5 @fontsource/ibm-plex-mono@5

then run this from 07_Executive_Delivery/. Verify a new build by loading the
output with the network disabled: it should make zero external requests and
still render all 22 store rows with the donut filter and column sorts working.
"""
import base64
import pathlib
import re
import sys

SRC = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "Inventory Visibility Dashboard.dc.html")
OUT = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else "dashboard_standalone.html")

TITLE = "NorthStar Southwest — Inventory Visibility Dashboard"

FONTS = [
    ("Newsreader", 400, "fonts/node_modules/@fontsource/newsreader/files/newsreader-latin-400-normal.woff2"),
    ("Newsreader", 500, "fonts/node_modules/@fontsource/newsreader/files/newsreader-latin-500-normal.woff2"),
    ("IBM Plex Sans", 400, "fonts/node_modules/@fontsource/ibm-plex-sans/files/ibm-plex-sans-latin-400-normal.woff2"),
    ("IBM Plex Sans", 500, "fonts/node_modules/@fontsource/ibm-plex-sans/files/ibm-plex-sans-latin-500-normal.woff2"),
    ("IBM Plex Sans", 600, "fonts/node_modules/@fontsource/ibm-plex-sans/files/ibm-plex-sans-latin-600-normal.woff2"),
    ("IBM Plex Mono", 400, "fonts/node_modules/@fontsource/ibm-plex-mono/files/ibm-plex-mono-latin-400-normal.woff2"),
    ("IBM Plex Mono", 500, "fonts/node_modules/@fontsource/ibm-plex-mono/files/ibm-plex-mono-latin-500-normal.woff2"),
    ("IBM Plex Mono", 600, "fonts/node_modules/@fontsource/ibm-plex-mono/files/ibm-plex-mono-latin-600-normal.woff2"),
]

RUNTIME = [
    "vendnpm/node_modules/react/umd/react.production.min.js",
    "vendnpm/node_modules/react-dom/umd/react-dom.production.min.js",
    "support.js",
]


def font_face_css():
    rules = []
    for family, weight, path in FONTS:
        b64 = base64.b64encode(pathlib.Path(path).read_bytes()).decode("ascii")
        rules.append(
            "@font-face{font-family:'%s';font-style:normal;font-weight:%d;font-display:swap;"
            "src:url(data:font/woff2;base64,%s) format('woff2');}" % (family, weight, b64)
        )
    return "\n".join(rules)


def main():
    html = SRC.read_text()

    # 1. Drop the document scaffold. The Artifact host supplies doctype/head/body,
    #    and a nested <html> would be invalid inside the wrapper.
    html = re.sub(r"(?is)^.*?<body>\s*", "", html)
    html = re.sub(r"(?is)\s*</body>\s*</html>\s*$", "", html)
    if "<x-dc>" not in html:
        sys.exit("expected an <x-dc> root after stripping the scaffold")

    # 2. Replace the blocked Google Fonts links with inlined faces.
    before = html
    html = re.sub(r'(?i)\s*<link[^>]*fonts\.(googleapis|gstatic)\.com[^>]*>', "", html)
    if html == before:
        sys.exit("no Google Fonts links found — export format changed, re-check")
    if "fonts.googleapis.com" in html or "fonts.gstatic.com" in html:
        sys.exit("a Google Fonts reference survived the strip")

    # 3. Inline the runtime ahead of the markup so support.js finds React already
    #    present and never reaches for the CDN.
    scripts = []
    for path in RUNTIME:
        js = pathlib.Path(path).read_text()
        if re.search(r"(?i)</script", js):
            sys.exit(f"{path} contains a literal </script and cannot be inlined verbatim")
        scripts.append("<script>\n%s\n</script>" % js)

    head = "<title>%s</title>\n<style>\n%s\n</style>\n%s" % (
        TITLE, font_face_css(), "\n".join(scripts)
    )
    OUT.write_text(head + "\n" + html)
    print(f"wrote {OUT} ({OUT.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
