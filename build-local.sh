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

# Check if VERSION.json exists
if [ ! -f VERSION.json ]; then
    echo "Error: VERSION.json not found"
    exit 1
fi

# Extract metadata and digests from VERSION.json
VERSION=$(jq -r '.VERSION // .version // "1.0.0"' VERSION.json)
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "local-build")

# Extract digests
DEBIAN_DIGEST_AMD64=$(jq -r '.DEBIAN_DIGEST_AMD64 // "sha256:placeholder"' VERSION.json)
DEBIAN_DIGEST_ARM64=$(jq -r '.DEBIAN_DIGEST_ARM64 // "sha256:placeholder"' VERSION.json)
DISTROLESS_DIGEST_AMD64=$(jq -r '.DISTROLESS_DIGEST_AMD64 // "sha256:placeholder"' VERSION.json)
DISTROLESS_DIGEST_ARM64=$(jq -r '.DISTROLESS_DIGEST_ARM64 // "sha256:placeholder"' VERSION.json)
DISTROLESS_DEBUG_DIGEST_AMD64=$(jq -r '.DISTROLESS_DEBUG_DIGEST_AMD64 // "sha256:placeholder"' VERSION.json)
DISTROLESS_DEBUG_DIGEST_ARM64=$(jq -r '.DISTROLESS_DEBUG_DIGEST_ARM64 // "sha256:placeholder"' VERSION.json)

# Select digests for arm64-debug build
DEBIAN_DIGEST="$DEBIAN_DIGEST_ARM64"
DISTROLESS_DIGEST="$DISTROLESS_DEBUG_DIGEST_ARM64"

# Check if digests are placeholders - if so, try to fetch real digests
if [ "$DEBIAN_DIGEST" = "sha256:placeholder" ] || [ -z "$DEBIAN_DIGEST" ]; then
    echo "Warning: Debian digest is placeholder, attempting to fetch real digest..."
    if command -v docker > /dev/null 2>&1; then
        REAL_DIGEST=$(docker buildx imagetools inspect debian:bookworm-slim --platform linux/arm64 --format '{{json .Manifest.Digest}}' 2>/dev/null | tr -d '"' || echo "")
        if [ -n "$REAL_DIGEST" ] && [ "$REAL_DIGEST" != "null" ]; then
            DEBIAN_DIGEST="sha256:$REAL_DIGEST"
            echo "Fetched Debian digest: $DEBIAN_DIGEST"
        else
            echo "Error: Could not fetch Debian digest. Please update VERSION.json with real digests."
            exit 1
        fi
    else
        echo "Error: Docker not available to fetch digest. Please update VERSION.json with real digests."
        exit 1
    fi
fi

if [ "$DISTROLESS_DIGEST" = "sha256:placeholder" ] || [ -z "$DISTROLESS_DIGEST" ]; then
    echo "Warning: Distroless digest is placeholder, attempting to fetch real digest..."
    if command -v docker > /dev/null 2>&1; then
        REAL_DIGEST=$(docker buildx imagetools inspect gcr.io/distroless/base-debian12:debug-arm64 --format '{{json .Manifest.Digest}}' 2>/dev/null | tr -d '"' || echo "")
        if [ -n "$REAL_DIGEST" ] && [ "$REAL_DIGEST" != "null" ]; then
            DISTROLESS_DIGEST="sha256:$REAL_DIGEST"
            echo "Fetched Distroless digest: $DISTROLESS_DIGEST"
        else
            echo "Error: Could not fetch Distroless digest. Please update VERSION.json with real digests."
            exit 1
        fi
    else
        echo "Error: Docker not available to fetch digest. Please update VERSION.json with real digests."
        exit 1
    fi
fi

echo "Version: $VERSION"
echo "Build date: $BUILD_DATE"
echo "Git commit: $GIT_COMMIT"
echo "Debian digest (ARM64): ${DEBIAN_DIGEST:-not set}"
echo "Distroless digest (ARM64 debug): ${DISTROLESS_DIGEST:-not set}"
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

# Build the image with arm64 architecture
# Digests are now guaranteed to be valid (fetched if needed)
docker buildx build \
    --platform linux/arm64 \
    --build-arg "VERSION=$VERSION" \
    --build-arg "BUILD_DATE=$BUILD_DATE" \
    --build-arg "GIT_COMMIT=$GIT_COMMIT" \
    --build-arg "DEBIAN_DIGEST=$DEBIAN_DIGEST" \
    --build-arg "DISTROLESS_DIGEST=$DISTROLESS_DIGEST" \
    --build-arg "DEBIAN_DIGEST_AMD64=$DEBIAN_DIGEST_AMD64" \
    --build-arg "DEBIAN_DIGEST_ARM64=$DEBIAN_DIGEST_ARM64" \
    --build-arg "DISTROLESS_DIGEST_AMD64=$DISTROLESS_DIGEST_AMD64" \
    --build-arg "DISTROLESS_DIGEST_ARM64=$DISTROLESS_DIGEST_ARM64" \
    --build-arg "DISTROLESS_DEBUG_DIGEST_AMD64=$DISTROLESS_DEBUG_DIGEST_AMD64" \
    --build-arg "DISTROLESS_DEBUG_DIGEST_ARM64=$DISTROLESS_DEBUG_DIGEST_ARM64" \
    --build-arg "TARGETARCH=arm64" \
    --build-arg "TARGETVARIANT=debug" \
    --build-arg "LIB_DIR=aarch64-linux-gnu" \
    --build-arg "LD_SO=ld-linux-aarch64.so.1" \
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

