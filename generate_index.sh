#! /usr/bin/env bash
set -euo pipefail

gen_index_md() {
    echo "---"
    echo "title: Christian Scott"
    echo "isindex: true"
    echo "---"
    echo

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

            local nice_date
            nice_date="$(date -d "${post_date}" '+%B %Y')"

            echo "${post_date} <p>[${post_title}](/${post_name})</p>"
        done
    } | sort -r | cut -f 2- -d ' '
}

main() {
    local output="${1}"
    shift

    gen_index_md "$@" > "${output}"
}

main "$@"
