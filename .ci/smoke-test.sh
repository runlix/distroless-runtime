#!/bin/bash
set -euo pipefail

echo "Testing image: $IMAGE_TAG"

test -n "${IMAGE_TAG:-}"
docker image inspect "$IMAGE_TAG" > /dev/null

user="$(docker inspect --format='{{.Config.User}}' "$IMAGE_TAG")"
workdir="$(docker inspect --format='{{.Config.WorkingDir}}' "$IMAGE_TAG")"
architecture="$(docker inspect --format='{{.Architecture}}' "$IMAGE_TAG")"

test "$user" = "65532:65532"
test "$workdir" = "/app"

# Distroless images do not ship a shell, so the smoke test uses the
# architecture-specific dynamic loader as the minimal runtime probe.
case "$architecture" in
  amd64)
    loader="/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2"
    ;;
  arm64)
    loader="/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1"
    ;;
  *)
    echo "Unsupported image architecture: $architecture" >&2
    exit 1
    ;;
esac

echo "Running dynamic loader smoke test with $loader"
docker run --rm --entrypoint "$loader" "$IMAGE_TAG" --help > /tmp/distroless-runtime-smoke.log 2>&1

if ! grep -Eq 'Usage:|You have invoked|Shared library loader' /tmp/distroless-runtime-smoke.log; then
  echo "Unexpected dynamic loader output" >&2
  cat /tmp/distroless-runtime-smoke.log >&2
  exit 1
fi

rm -f /tmp/distroless-runtime-smoke.log
