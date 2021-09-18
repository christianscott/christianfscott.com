#! /usr/bin/env nix-shell
#! nix-shell -i bash --pure default.nix

md_to_html() {
  local input="$1"
  pandoc \
    --standalone \
    --template post.tmpl \
    --from markdown \
    --to html \
    "${input}"
}

generate_post() {
  local post="${1}"
  local post_name
  post_name="$(basename "${post}")"

  mkdir -p "out/${post_name}"

  md_to_html "${post}/index.md" > "out/${post_name}/index.html"

  pandoc --template metadata.tmpl "${post}/index.md" > "out/${post_name}/metadata.json"

  cp "${post}/"* "out/${post_name}"

  echo "Generated ${post_name} 🚀"
}

generate_index() {
  {
    echo "---"
    echo "title: Christian Scott"
    echo "---"

    {
      for post in posts/*
      do
        local post_name
        post_name="$(basename "${post}")"

        local post_title
        local post_date
        post_title=$(jq -r .title "out/${post_name}/metadata.json")
        post_date=$(jq -r .date "out/${post_name}/metadata.json")

        echo "${post_date} <p>[${post_title}](/${post_name})</p>"
      done
    } | sort -r | cut -f 2- -d ' '
  } > out/index.md

  md_to_html out/index.md > out/index.html
  rm out/index.md

  echo "Generated index 🚀"
}

main() {
  rm -rf out/*
  mkdir -p out/

  local post
  for post in posts/*
  do
    generate_post "${post}" &
  done

  local failed=0
  for job in `jobs -p`
  do
    wait "${job}" || failed=1
  done

  # wait for all subprocesses
  wait < <(jobs -p)

  generate_index

  cp static/* out/
}

main "$@"
