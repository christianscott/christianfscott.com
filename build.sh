#! /usr/bin/env bash
set -euo pipefail

generate_bazelrc() {
  cat << EOF > 'generated.bazelrc'
build --bes_results_url=https://app.buildbuddy.io/invocation/
build --bes_backend=grpcs://cloud.buildbuddy.io
build --remote_cache=grpcs://cloud.buildbuddy.io
build --remote_timeout=3600
build --remote_header=${BUILDBUDDY_API_KEY}
EOF
}

main() {
  if [[ -n "${BUILDBUDDY_API_KEY:-}" && "${NETLIFY:-}" -eq 'true' ]]; then
    generate_bazelrc
  fi
  bazelisk build //...
}

main
