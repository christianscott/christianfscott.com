load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load("//:posts.bzl", "index_page", "post_page", "rss_feed")

[post_page(post_md = post_md) for post_md in glob(["posts/**/index.md"])]

index_page()

rss_feed()

[
    copy_file(
        name = "{static_file}.copy".format(static_file = static_file),
        src = static_file,
        out = static_file.replace("static/", ""),
    )
    for static_file in glob(
        ["static/*"],
        allow_empty = False,
    )
]
