#!/usr/bin/env python3

import argparse
import json
import logging
import os
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Optional


@dataclass
class Post:
    """Represents a blog post."""

    title: str
    date: datetime
    path: Path
    name: str
    draft: bool = False

    @classmethod
    def read(cls, path: Path) -> "Post":
        """Read a post from a markdown file, extracting metadata using pandoc."""
        # pandoc will print JSON to stdout
        result = subprocess.run(
            ["./bin/pandoc", "--template", "metadata.tmpl", str(path)],
            capture_output=True,
            text=True,
            check=True,
        )
        metadata = json.loads(result.stdout)

        post_dir = path.parent
        post_name = post_dir.name

        return cls(
            title=metadata["title"],
            date=datetime.strptime(metadata["date"], "%Y-%m-%d"),
            path=path,
            name=post_name,
            draft=metadata.get("draft", False),
        )


@dataclass
class Link:
    """Represents an external link."""

    title: str
    date: datetime
    url: str
    name: str

    @classmethod
    def read(cls, path: Path) -> "Link":
        """Read a link from a JSON file."""
        with open(path, "r") as f:
            data = json.load(f)

        return cls(
            title=data["title"],
            date=datetime.strptime(data["date"], "%Y-%m-%d"),
            url=data["url"],
            name=path.stem,
        )


def generate_post_html(post: Post, outdir: Path) -> None:
    """Generate HTML for a single post."""

    post_outdir = outdir / post.name
    post_outdir.mkdir(parents=True, exist_ok=True)

    post_dir = post.path.parent
    for file in post_dir.iterdir():
        if not file.is_file():
            continue
        if file.suffix in [".md", ".html"]:
            continue
        shutil.copy2(file, post_outdir / file.name)

    nice_date = post.date.strftime("%B %Y")

    pandoc_args = [
        "./bin/pandoc",
        "--from",
        "markdown",
        "--to",
        "html5",
        "--variable",
        f"nice_date={nice_date}",
        "--highlight-style",
        "haddock",
        "--template",
        "post.tmpl",
    ]
    if post.draft:
        pandoc_args.extend(["--variable", "draft=true"])

    pandoc_args.append(str(post.path))

    dest = post_outdir / "index.html"
    with open(dest, "w") as f:
        subprocess.run(pandoc_args, stdout=f, check=True)

    return dest


def generate_index_html(posts: list[Post], links: list[Link], outfile: Path) -> None:
    """Generate the index.html page."""

    items = []
    for post in posts:
        if post.draft:
            continue
        items.append((post.date, f"<p>[{post.title}](/{post.name})</p>"))
    for link in links:
        items.append((link.date, f"<p>[↗ {link.title}]({link.url})</p>"))

    # sort links and posts by date, newest first
    items.sort(key=lambda x: x[0], reverse=True)

    markdown_lines = [
        "---",
        "title: Christian Scott",
        "isindex: true",
        "---",
        "",
    ]

    last_year = None
    for date, html in items:
        year = date.strftime("%Y")
        if last_year != year:
            last_year = year
            markdown_lines.append(f"<h2>{year}</h2>")
        markdown_lines.append(html)

    markdown_content = "\n".join(markdown_lines)

    with open(outfile, "w") as f:
        subprocess.run(
            [
                "./bin/pandoc",
                "--from",
                "markdown",
                "--to",
                "html5",
                "--template",
                "post.tmpl",
            ],
            input=markdown_content,
            text=True,
            stdout=f,
            check=True,
        )


def generate_rss_xml(posts: list[Post], links: list[Link], outfile: Path) -> None:
    """Generate the RSS feed."""

    rss_lines = [
        '<?xml version="1.0" encoding="UTF-8" ?>',
        '<rss version="2.0">',
        "<channel>",
        "  <title>Christian Scott</title>",
        "  <link>https://www.christianfscott.com</link>",
    ]

    for post in posts:
        if post.draft:
            continue
        rss_lines.extend(
            [
                "  <item>",
                f"    <title>{post.title}</title>",
                f"    <link>https://www.christianfscott.com/{post.name}</link>",
                f"    <description>{post.title}</description>",
                f'    <pubDate>{post.date.strftime("%Y-%m-%d")}</pubDate>',
                "  </item>",
            ]
        )

    rss_lines.extend(
        [
            "</channel>",
            "</rss>",
        ]
    )

    with open(outfile, "w") as f:
        f.write("\n".join(rss_lines) + "\n")


def main():
    parser = argparse.ArgumentParser(description="Build the static site")
    parser.add_argument("-o", "--outdir", required=True, help="Output directory")
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format="[%(asctime)s]: %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S%z",
    )

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    with ThreadPoolExecutor() as executor:
        posts = list(executor.map(Post.read, Path("posts").rglob("index.md")))
        links = list(executor.map(Link.read, Path("links").glob("*.json")))
    logging.info("found %d posts and %d links", len(posts), len(links))

    with ThreadPoolExecutor() as executor:
        futures = [executor.submit(generate_post_html, post, outdir) for post in posts]
        for future in futures:
            dest = future.result()
            logging.info(f"generated %s", dest)

    index_html_out = outdir / "index.html"
    generate_index_html(posts, links, index_html_out)
    logging.info("generated %s", index_html_out)

    index_rss_out = outdir / "index.xml"
    generate_rss_xml(posts, links, index_rss_out)
    logging.info("generated %s (RSS feed)", index_rss_out)

    static_dir = Path("static")
    if static_dir.exists():
        for item in static_dir.iterdir():
            if item.is_file():
                shutil.copy2(item, outdir / item.name)
                logging.info("copied %s", outdir / item.name)
            elif item.is_dir():
                shutil.copytree(item, outdir / item.name, dirs_exist_ok=True)


if __name__ == "__main__":
    main()
