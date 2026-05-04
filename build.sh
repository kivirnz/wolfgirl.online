#!/bin/bash
set -e

# -------- CONFIG --------
SITE_URL="https://wolfgirl.online"
MD_DIR="blog-md"
OUT_DIR="blog"
FEED="feed.xml"
# ------------------------

echo "[*] Building blog posts..."

mkdir -p "$OUT_DIR"

# Convert Markdown → HTML
for md_file in "$MD_DIR"/*.md; do
  filename=$(basename "$md_file" .md)

  # Extract formatted dates using Python
  dates=$(python3 -c "
import sys, yaml, datetime, re

def parse_date(d):
    if isinstance(d, datetime.date):
        return datetime.datetime.combine(d, datetime.time())
    if isinstance(d, str):
        for fmt in ('%Y-%m-%d', '%B %Y'):
            try:
                return datetime.datetime.strptime(d, fmt)
            except:
                pass
    return datetime.datetime(1970, 1, 1)

try:
    with open('$md_file', 'r', encoding='utf-8') as f:
        content = f.read(2048) # Read header
    m = re.match(r'^---\s*\n(.*?)\n---\s*\n', content, re.S)
    if m:
        meta = yaml.safe_load(m.group(1))
        d = meta.get('date', '1970-01-01')
        dt = parse_date(d)
        # Output: ISO|Display
        print(f\"{dt.strftime('%Y-%m-%d')}|{dt.day} {dt.strftime('%B %Y')}\")
    else:
        print('1970-01-01|1 January 1970')
except:
    print('1970-01-01|1 January 1970')
")

  date_iso=$(echo "$dates" | cut -d'|' -f1)
  date_display=$(echo "$dates" | cut -d'|' -f2)

  mkdir -p "$OUT_DIR/$filename"

  pandoc "$md_file" \
    -f gfm+footnotes \
    -t html \
    -s \
    --metadata date="$date_display" \
    --metadata date_iso="$date_iso" \
    --template=templates/post.html \
    -o "$OUT_DIR/$filename/index.html"

  echo "  Built: $md_file → $OUT_DIR/$filename/index.html"
done

echo "[*] Generating RSS feed..."

python3 - <<'PY'
import glob, yaml, datetime, re

SITE = "https://wolfgirl.online"
MD_DIR = "blog-md"
FEED = "feed.xml"

def parse_date(d):
    if isinstance(d, datetime.date):
        return datetime.datetime.combine(d, datetime.time())
    for fmt in ("%Y-%m-%d", "%B %Y"):
        try:
            return datetime.datetime.strptime(d, fmt)
        except:
            pass
    print(f"WARNING: bad date '{d}', using epoch")
    return datetime.datetime(1970,1,1)

items = []

for path in sorted(glob.glob(f"{MD_DIR}/*.md")):
    with open(path, encoding="utf-8") as f:
        text = f.read()

    # Extract YAML frontmatter safely
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.S)
    if not m:
        print(f"WARNING: No frontmatter in {path}")
        continue

    meta = yaml.safe_load(m.group(1))

    title = meta.get("title", "Untitled")
    slug = meta.get("slug", path.split("/")[-1].replace(".md", ""))
    desc = meta.get("description", "")
    date_raw = meta.get("date", "1970-01-01")

    dt = parse_date(date_raw)
    pubdate = dt.strftime("%a, %d %b %Y 00:00:00 GMT")

    url = f"{SITE}/blog/{slug}/"

    items.append(f"""
    <item>
      <title><![CDATA[{title}]]></title>
      <link>{url}</link>
      <guid>{url}</guid>
      <pubDate>{pubdate}</pubDate>
      <description><![CDATA[{desc}]]></description>
    </item>
    """)

rss = f"""<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
<channel>
<title>Riley's Blog (wolfgirl.online)</title>
<link>{SITE}</link>
<description>Blog posts</description>
{''.join(items)}
</channel>
</rss>
"""

open(FEED, "w").write(rss)
print("[*] RSS generated!")
PY

echo "[✓] Build complete."
