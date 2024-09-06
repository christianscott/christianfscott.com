load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")

def post_page(post_md):
    post_dir = paths.dirname(post_md)
    post_name = paths.basename(post_dir)

    static_files = native.glob(
        include = ["{post_dir}/*".format(post_dir = post_dir)],
        exclude = ["**/*.md", "**/*.html"],
    )
    for static_file in static_files:
        copy_file(
            name = "{static_file}.copy".format(static_file = static_file),
            src = static_file,
            out = "{post}/{static_file}".format(
                post = post_name,
                static_file = paths.basename(static_file),
            ),
        )

    native.genrule(
        name = "{post}-metadata".format(post = post_name),
        srcs = [post_md, "metadata.tmpl"],
        outs = ["{post}/metadata.json".format(post = post_name)],
        cmd = "pandoc --template metadata.tmpl {post_md} > $@".format(post_md=post_md),
    )

    native.genrule(
        name = "{post}-html".format(post = post_name),
        srcs = [post_md, "post.tmpl", "{post}/metadata.json".format(post=post_name)],
        outs = ["{post}/index.html".format(post = post_name)],
        cmd = "\n".join([
            "date=$$(jq -r .date $(location :{post}/metadata.json))".format(post=post_name),
            "nice_date=$$(date -d $$date '+%B %Y')",
            "pandoc --from markdown --to html5 --variable=nice_date=\"$$nice_date\" --highlight-style=haddock --template post.tmpl {post_md} > $@".format(post_md=post_md),
        ]),
    )


def index_page():
    posts = native.glob(["posts/**/index.md"])
    metadata = [":{post}-metadata".format(post=paths.basename(paths.dirname(post))) for post in posts]

    native.genrule(
        name = "index-md",
        srcs = metadata + ["generate_index.sh"],
        outs = ["index.md"],
        cmd = "./generate_index.sh $@",
    )

    native.genrule(
        name = "index-html",
        srcs = [":index.md", "post.tmpl"],
        outs = ["index.html"],
        cmd = " ".join([
            "pandoc",
            "--from markdown",
            "--to html5",
            "--template post.tmpl",
            "$(location :index.md)",
            "> $@",
        ]),
    )

def rss_feed():
    posts = native.glob(["posts/**/index.md"])
    metadata = [":{post}-metadata".format(post=paths.basename(paths.dirname(post))) for post in posts]

    native.genrule(
        name = "rss",
        srcs = metadata + ["generate_rss.sh"],
        outs = ["index.xml"],
        cmd = "./generate_rss.sh $@",
    )
