"""
Download arXiv PDFs for a topic, ranked by arXiv's relevance sort.
Files are prefixed with rank (001_, 002_, ...) so directory order == relevance order.

python arxiv_download.py --keyword "quantum battery" -n 30 -o papers
"""
import argparse
import re
import time
from pathlib import Path
import requests

import arxiv


def slug(s: str, n: int = 60) -> str:
    return re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")[:n]

def score(r, keyword):
    terms = [term for term in re.findall(r"[a-z0-9]+", keyword.lower()) if term]
    title = r.title.lower()
    summary = r.summary.lower()
    return sum(
        5 * title.count(term) + summary.count(term)
        for term in terms
    )


def prepare_topic_directory(out, keyword):
    out.mkdir(parents=True, exist_ok=True)
    marker = out / ".topic"
    normalized = keyword.strip().lower()
    previous = marker.read_text().strip().lower() if marker.exists() else None
    if previous != normalized:
        for pdf in out.glob("*.pdf"):
            pdf.unlink()
        marker.write_text(normalized)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("-k", "--keyword", default="supercapacitor",
                   help="single keyword or topic used to search and rank arXiv papers")
    p.add_argument("-q", "--query", help="optional custom arXiv query syntax")
    p.add_argument("-n", "--max", type=int, default=20, help="number of papers")
    p.add_argument("-o", "--out", default="papers")
    a = p.parse_args()

    keyword = a.keyword.strip()
    if not keyword:
        p.error("--keyword cannot be empty")

    out = Path(a.out)
    prepare_topic_directory(out, keyword)
    query = a.query or f'all:"{keyword}"'

    client = arxiv.Client(page_size=50, delay_seconds=3, num_retries=3)
    search = arxiv.Search(
        query=query,
        max_results=300,
        sort_by=arxiv.SortCriterion.Relevance,
    )
    results = sorted(
        client.results(search),
        key=lambda paper: score(paper, keyword),
        reverse=True,
    )[:a.max]

    for rank, r in enumerate(results, start=1):
        sid = r.get_short_id().replace("/", "_")
        name = f"{rank:03d}_{sid}_{slug(r.title)}.pdf"
        if (out / name).exists():
            print(f"[skip] {name}")
            continue
        try:
            resp = requests.get(
                f"https://arxiv.org/pdf/{r.get_short_id()}",
                headers={"User-Agent": "arxiv-downloader/1.0"},
                timeout=60,
            )
            resp.raise_for_status()
            (out / name).write_bytes(resp.content)
            print(f"[ok]   {name}")
        except Exception as e:
            print(f"[fail] {name}: {e}")
        time.sleep(3)


if __name__ == "__main__":

    main()