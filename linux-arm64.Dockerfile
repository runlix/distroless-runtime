# Builder tag from VERSION.json builder.tag (e.g., "bookworm-slim")
ARG BUILDER_TAG=bookworm-slim
# Base tag (variant-arch) from VERSION.json base.tag (e.g., "latest-arm64", "debug-arm64")
ARG BASE_TAG=latest-arm64
# Selected digests (build script will set based on target configuration)
# Default to empty string - build script should always provide valid digests
# If empty, FROM will fail (which is desired to enforce digest pinning)
ARG BUILDER_DIGEST=""
ARG BASE_DIGEST=""

# STAGE 1 — build base libs
# Build script will pass BUILDER_TAG and BUILDER_DIGEST from VERSION.json
# Format: debian:bookworm-slim@sha256:digest (when digest provided)
FROM docker.io/library/debian:${BUILDER_TAG}@${BUILDER_DIGEST} AS runtime-deps

# Use BuildKit cache mounts to persist apt cache between builds
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    libc6 \
    libssl3 \
    libicu72 \
    ca-certificates \
    tzdata \
 && rm -rf /var/lib/apt/lists/*

# STAGE 2 — distroless final image
# Build script will pass BASE_TAG (from VERSION.json base.tag) and BASE_DIGEST
# Format: gcr.io/distroless/base-debian12:latest-arm64@sha256:digest (when digest provided)
FROM gcr.io/distroless/base-debian12:${BASE_TAG}@${BASE_DIGEST}

# Hardcoded for arm64 - no conditionals needed!
ARG LIB_DIR=aarch64-linux-gnu
ARG LD_SO=ld-linux-aarch64.so.1

# Copy runtime dependencies
# Copy dynamic linker (required for dynamically linked binaries)
# Note: COPY creates parent directories automatically
COPY --from=runtime-deps /lib/${LIB_DIR}/${LD_SO} /lib/${LIB_DIR}/${LD_SO}
# Copy shared libraries (libc6, libssl3, libicu72, etc.) - combined into single layer
COPY --from=runtime-deps /usr/lib/${LIB_DIR} /usr/lib/${LIB_DIR}
# Copy SSL certificates and timezone data
COPY --from=runtime-deps /etc/ssl/certs /etc/ssl/certs
COPY --from=runtime-deps /usr/share/zoneinfo /usr/share/zoneinfo

# K8s security default
USER 65532:65532
WORKDIR /app
