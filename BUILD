load("//:posts.bzl", "post_page", "index_page")

[post_page(post_md = post_md) for post_md in glob(["posts/**/index.md"])]

index_page()
