#! /usr/bin/env bash
set -euo pipefail

gen_index_md() {
    cat <<EOF
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
<channel>
  <title>Christian Scott</title>
  <link>https://www.christianfscott.com</link>
EOF

    {
        for metadata in `find . -name metadata.json`
        do
            local post_title
            local post_date
            post_title=$(jq -r .title "${metadata}")
            post_date=$(jq -r .date "${metadata}")

            local post_name="${metadata}"
            post_name=$(dirname "${post_name}")
            post_name=$(basename "${post_name}")

            cat <<EOF
  <item>
    <title>${post_title}</title>
    <link>https://www.christianfscott.com/${post_name}</link>
    <description>${post_title}</description>
    <pubDate>${post_date}</pubDate>
  </item>
EOF
        done
    }

    cat <<EOF
</channel>
</rss>
EOF
}

main() {
    local output="${1}"
    shift

    gen_index_md "$@" > "${output}"
}

main "$@"
