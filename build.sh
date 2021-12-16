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
  if [[ "${NETLIFY:-}" == true && -n "${BUILDBUDDY_API_KEY:-}" ]]; then
    generate_bazelrc
  fi

  local bazel
  if command -v bazelisk > /dev/null; then
    bazel='bazelisk'
  else
    bazel='./bazelw'
  fi

  "${bazel}" build //...
  cp -Lr bazel-bin/ "$1"
}

main "$1"
