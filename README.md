# christianfscott.com

## Prerequisites

This project uses [dotslash](https://github.com/facebook/dotslash) to manage dependencies. You can find installation instructions [here](https://dotslash-cli.com/docs/installation/).

The project dependencies (pandoc and jq) are automatically downloaded and managed via dotslash when you run the build script.

## Building the Site

The main build script is `build_site.sh`. It generates static HTML files from markdown posts using pandoc.

```bash
./build_site.sh -o <output_directory>
```

Example:
```bash
./build_site.sh -o out/
```

The build process:
1. Finds all `posts/*/index.md` files
2. Generates HTML using pandoc with the `post.tmpl` template
3. Creates an index page that groups all posts by year
4. Generates an RSS feed at `index.xml`
5. Copies static files from the `static/` directory

When developing locally you can serve the output directory using a simple HTTP server:

```bash
cd out
python3 -m http.server 8000
```

Then visit `http://localhost:8000` in your browser.

## Adding a New Post

Use the `new_post.sh` script to create a new post:

```bash
./new_post.sh "Your Post Title" "your-post-slug"
```

This creates a new directory `posts/your-post-slug/` with an `index.md` file containing:

```markdown
---
title: Your Post Title
date: "2025-01-09T12:34:56.789Z"
---

The world is your oyster.
```

### Post Structure

- **Posts**: Each post lives in `posts/<slug>/index.md`
- **Assets**: Any non-markdown files in the post directory are copied to the output
- **Metadata**: Posts use YAML frontmatter for title and date
- **Content**: Written in markdown, processed by pandoc

### Adding External Links

External links (like conference talks, papers, etc.) are stored as JSON files in the `links/` directory:

```json
{
    "title": "Your Link Title",
    "date": "2024-11-17",
    "url": "https://example.com"
}
```

These appear in the main index alongside blog posts, marked with a ↗ symbol.

## Deployment

The site is automatically deployed to Cloudflare Pages via GitHub Actions when changes are pushed to the `master` branch.

The deployment workflow (`.github/workflows/deploy.yml`):
1. Installs dotslash
2. Runs the build script
3. Deploys to Cloudflare Pages using wrangler

### Cloudflare Configuration

The site is deployed to Cloudflare Pages with the project name `christianfscott-dot-com`. Deployment requires:
- `CLOUDFLARE_API_TOKEN` (GitHub secret)
- `CLOUDFLARE_ACCOUNT_ID` (GitHub secret)
