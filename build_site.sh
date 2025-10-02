#! /usr/bin/env bash

set -euo pipefail

main() {
    local outdir=''
    while getopts "o:" opt; do
        case $opt in
            o)
                outdir=$OPTARG
                ;;
            \?)
                usage
                ;;
        esac
    done

    if [[ -z "${outdir}" ]]; then
        usage
    fi

    mkdir -p "${outdir}"

    local tmpdir
    tmpdir=$(mktemp -d)

    for post in $(find posts -name index.md -type f); do
        log "building post ./${post}"
        generate_post_html "${post}" "${outdir}" "${tmpdir}"
    done

    log "building index.html"
    generate_index_html "${outdir}" "${tmpdir}"

    log "building index.xml (RSS feed)"
    generate_rss_xml "${outdir}" "${tmpdir}"

    log "copying static files"
    cp -r static/* "${outdir}"
}

generate_post_html() {
    local post="${1}"
    local outdir="${2}"
    local tmpdir="${3}"

    local post_dir
    post_dir=$(dirname "$post")
    local post_name
    post_name=$(basename "$post_dir")

    mkdir -p "${outdir}/${post_name}"

    # find all files except for *.md and *.html files
    for static_file in $(find "${post_dir}" -type f -not -name '*.md' -not -name '*.html'); do
        cp "${static_file}" "${outdir}/${post_name}/$(basename "${static_file}")"
    done

    # create post metadata json
    local post_metadata="${tmpdir}/${post_name}_metadata.json"
    ./bin/pandoc --template metadata.tmpl "${post}" > "${post_metadata}"

    # create post html
    local post_date=$(jq -r '.date' "${post_metadata}")
    local nice_date
    nice_date=$(reformat_date "${post_date}" '+%B %Y')
    ./bin/pandoc \
        --from markdown \
        --to html5 \
        --variable nice_date="${nice_date}" \
        --highlight-style haddock \
        --template post.tmpl \
        "${post}" > "${outdir}/${post_name}/index.html"
}

generate_index_html() {
    local outdir="${1}"
    local tmpdir="${2}"

    # copy all link/*.json files to $tmpdir
    cp -r links/*.json "${tmpdir}"

    local index_md="${tmpdir}/index.md"
    _print_index_md "${tmpdir}" > "${index_md}"

    ./bin/pandoc \
        --from markdown \
        --to html5 \
        --template post.tmpl \
        "${index_md}" > "${outdir}/index.html"
}

_print_index_md() {
    local tmpdir="${1}"

    echo "---"
    echo "title: Christian Scott"
    echo "isindex: true"
    echo "---"
    echo

    local last_printed_year=''
    {
        for metadata in $(find "${tmpdir}" -name '*.json')
        do
            local post_title
            local post_date
            local post_url
            post_title=$(jq -r .title "${metadata}")
            post_date=$(jq -r .date "${metadata}")
            post_url=$(jq -r '.url // ""' "${metadata}")

            local post_name="${metadata}"
            post_name=$(basename "${post_name}" '.json')

            if [[ -z "${post_url}" ]]; then
                echo "${post_date} <p>[${post_title}](/${post_name})</p>"
            else
                echo "${post_date} <p>[↗ ${post_title}](${post_url})</p>"
            fi
        done
    } | sort -r | while read line; do
        local post_date
        post_date=$(cut -f 1 -d ' ' <<< $line)
        local html
        html=$(cut -f 2- -d ' ' <<< $line)

        local post_year
        post_year="$(reformat_date "${post_date}" '+%Y')"
        if [[ "${last_printed_year}" == '' ]] || [[ "${last_printed_year}" != "${post_year}" ]]; then
            last_printed_year="${post_year}"
            echo "<h2>${post_year}</h2>"
        fi
        echo "${html}"
    done
}

generate_rss_xml() {
    local outdir="${1}"
    local tmpdir="${2}"
    _print_rss_xml "${tmpdir}" > "${outdir}/index.xml"
}

_print_rss_xml() {
    local tmpdir="${1}"

    cat <<EOF
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
<channel>
  <title>Christian Scott</title>
  <link>https://www.christianfscott.com</link>
EOF

    {
        for metadata in $(find "${tmpdir}" -name '*_metadata.json')
        do
            local post_title
            local post_date
            post_title=$(./bin/jq -r .title "${metadata}")
            post_date=$(./bin/jq -r .date "${metadata}")

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

usage() {
    echo "usage: $0 -o <output directory>" >&2
    exit 1
}

log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

# Reprints a date using a different format
reformat_date() {
  local date="$1"
  local format="$2"
  # use -f -j on macos
  if [[ $(uname) == "Darwin" ]]; then
    date -j -f '%Y-%m-%d' "$date" "$format"
  else
    date -d "$date" "$format"
  fi
}

main "$@"
