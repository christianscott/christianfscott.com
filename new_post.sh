#!/usr/bin/env bash

main() {
  local usage="usage: ${0} title slug"

  local title="${1:-}"
  if [[ "${title}" == '' ]]; then
    echo "missing title. ${usage}"
    exit 1
  fi

  local slug="${2:-}"
  if [[ "${slug}" == '' ]]; then
    echo "missing slug. ${usage}"
    exit 1
  fi
  if ! [[ "${slug}" =~ ^[a-z-]+$ ]]; then
    echo "invalid slug. slugs can only contain lowercase letters and hyphens (i.e. they must match /^[a-z-]+$/)"
    exit 1
  fi

  local date
  date=$(node -e 'console.log(new Date())')

  mkdir -p "posts/${slug}"
  echo "creating posts/${slug}/index.md:"
  cat <<EOF | tee  "posts/${slug}/index.md"
---
title: $title
date: "$date"
---

The world is your oyster.
EOF

}

main "$@"
