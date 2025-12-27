#!/bin/bash
set -euo pipefail

# Local build script for distroless-runtime with arm64-debug architecture
# This script builds the image locally for arm64 while GitHub Actions continues
# to build for amd64 by default.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Default tag
TAG="${1:-distroless-runtime:arm64-debug-local}"

echo "Building distroless-runtime for arm64-debug architecture..."
echo "Tag: $TAG"
echo ""

# Check if docker buildx is available
if ! docker buildx version > /dev/null 2>&1; then
    echo "Error: docker buildx is not available. Please install Docker Buildx."
    exit 1
fi

# Ensure buildx builder exists and supports multi-platform
if ! docker buildx ls | grep -q "multiarch"; then
    echo "Creating buildx builder for multi-platform builds..."
    docker buildx create --name multiarch --use --bootstrap || true
    docker buildx use multiarch || true
fi

# Build the image with arm64 architecture
echo "Building image..."
docker buildx build \
    --platform linux/arm64 \
    --build-arg TARGETARCH=arm64 \
    --build-arg TARGETVARIANT=debug \
    --build-arg LIB_DIR=aarch64-linux-gnu \
    --build-arg LD_SO=ld-linux-aarch64.so.1 \
    --tag "$TAG" \
    --load \
    --file Dockerfile \
    .

echo ""
echo "Build completed successfully!"
echo "Image tagged as: $TAG"
echo ""
echo "To test the image, run:"
echo "  docker run --rm $TAG --help"

