# STAGE 1 — build base libs
FROM docker.io/library/debian:bookworm-slim AS runtime-deps

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
# ARGs before FROM are available to FROM statement
# TARGETARCH is automatically set by docker buildx based on --platform
# TARGETVARIANT defaults to "latest" for production builds, "debug" for local development
ARG TARGETARCH=amd64
ARG TARGETVARIANT=latest
FROM gcr.io/distroless/base-debian12:${TARGETVARIANT}-${TARGETARCH}

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

# K8s security default
USER 65532:65532
WORKDIR /app
CMD ["--help"]
