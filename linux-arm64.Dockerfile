ARG BUILDER_REF="docker.io/library/debian:bookworm-slim@sha256:1c5d4fd0caad88eb6cb62bcdbc2f580ef2523ab69e86abc2bd2a94703aac9f96"
ARG BASE_REF="gcr.io/distroless/base-debian12:latest-arm64@sha256:092d065d29d72957dc7a85519c3f911d6ad233fe6b53e7a9f42891e6464cc7d9"

FROM ${BUILDER_REF} AS runtime-deps

# Use BuildKit cache mounts to persist apt cache between builds
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libc6 \
    libssl3 \
    libicu72 \
    ca-certificates \
    tzdata \
 && rm -rf /var/lib/apt/lists/*

FROM ${BASE_REF}

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
