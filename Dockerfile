# Build metadata ARGs (available to all stages)
ARG VERSION=1.0.0
ARG BUILD_DATE
ARG GIT_COMMIT
# Base image digest ARGs (all digests for labels)
ARG DEBIAN_DIGEST_AMD64
ARG DEBIAN_DIGEST_ARM64
ARG DISTROLESS_DIGEST_AMD64
ARG DISTROLESS_DIGEST_ARM64
ARG DISTROLESS_DEBUG_DIGEST_AMD64
ARG DISTROLESS_DEBUG_DIGEST_ARM64
# Selected digests (build script will set based on TARGETARCH and TARGETVARIANT)
# Default to empty string - build script should always provide valid digests
# If empty, FROM will fail (which is desired to enforce digest pinning)
ARG DEBIAN_DIGEST=""
ARG DISTROLESS_DIGEST=""

# Architecture selection (set by build script)
ARG TARGETARCH=amd64

# STAGE 1 — build base libs
# Build script will pass DEBIAN_DIGEST with the correct digest for TARGETARCH
# If DEBIAN_DIGEST is empty or "sha256:placeholder", build script should not pass it
# Format: debian:bookworm-slim@sha256:digest (when digest provided)
FROM docker.io/library/debian:bookworm-slim@${DEBIAN_DIGEST} AS runtime-deps

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
# TARGETVARIANT defaults to "latest" for production builds, "debug" for local development
ARG TARGETVARIANT=latest
# Build script will pass DISTROLESS_DIGEST with the correct digest for TARGETARCH and TARGETVARIANT
# If DISTROLESS_DIGEST is empty or "sha256:placeholder", build script should not pass it
# Format: gcr.io/distroless/base-debian12:latest-amd64@sha256:digest (when digest provided)
FROM gcr.io/distroless/base-debian12:${TARGETVARIANT}-${TARGETARCH}@${DISTROLESS_DIGEST}

# Set architecture-specific paths based on TARGETARCH
ARG TARGETARCH=amd64
# Map architecture to library directory and dynamic linker
# amd64 -> x86_64-linux-gnu -> ld-linux-x86-64.so.2
# arm64 -> aarch64-linux-gnu -> ld-linux-aarch64.so.1
ARG LIB_DIR=x86_64-linux-gnu
ARG LD_SO=ld-linux-x86-64.so.2
# Set LIB_DIR and LD_SO based on TARGETARCH using build arg defaults
# These will be overridden by build-local.sh for arm64 builds

# Copy runtime dependencies
# Copy dynamic linker (required for dynamically linked binaries)
# Note: COPY creates parent directories automatically
COPY --from=runtime-deps /lib/${LIB_DIR}/${LD_SO} /lib/${LIB_DIR}/${LD_SO}
# Copy shared libraries (libc6, libssl3, libicu72, etc.) - combined into single layer
COPY --from=runtime-deps /usr/lib/${LIB_DIR} /usr/lib/${LIB_DIR}
# Copy SSL certificates and timezone data - combined into single layer
COPY --from=runtime-deps /etc/ssl/certs /etc/ssl/certs
COPY --from=runtime-deps /usr/share/zoneinfo /usr/share/zoneinfo

# Add metadata labels for traceability
LABEL org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      io.runlix.base.debian.digest.amd64="${DEBIAN_DIGEST_AMD64}" \
      io.runlix.base.debian.digest.arm64="${DEBIAN_DIGEST_ARM64}" \
      io.runlix.base.distroless.digest.amd64="${DISTROLESS_DIGEST_AMD64}" \
      io.runlix.base.distroless.digest.arm64="${DISTROLESS_DIGEST_ARM64}" \
      io.runlix.base.distroless.debug.digest.amd64="${DISTROLESS_DEBUG_DIGEST_AMD64}" \
      io.runlix.base.distroless.debug.digest.arm64="${DISTROLESS_DEBUG_DIGEST_ARM64}"

# K8s security default
USER 65532:65532
WORKDIR /app
CMD ["--help"]
