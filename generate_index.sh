#! /usr/bin/env bash
set -euo pipefail

gen_index_md() {
    echo "---"
    echo "title: Christian Scott"
    echo "isindex: true"
    echo "---"
    echo

    local last_printed_year=''
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

            echo "${post_date} <p>[${post_title}](/${post_name})</p>"
        done
    } | sort -r | while read line; do
        local post_date
        post_date=$(cut -f 1 -d ' ' <<< $line)
        local html
        html=$(cut -f 2- -d ' ' <<< $line)

        local post_year
        post_year="$(date -d "${post_date}" '+%Y')"
        if [[ "${last_printed_year}" == '' ]] || [[ "${last_printed_year}" != "${post_year}" ]]; then
            last_printed_year="${post_year}"
            echo "<h2>${post_year}</h2>"
        fi
        echo "${html}"
    done
}

main() {
    local output="${1}"
    shift

    gen_index_md "$@" > "${output}"
}

main "$@"
