# Build metadata ARGs (available to all stages)
ARG VERSION=1.0.0
ARG BUILD_DATE
ARG GIT_COMMIT

# Platform-specific digest (workflow passes amd64 digest)
ARG DEBIAN_DIGEST
ARG DISTROLESS_DIGEST
ARG TARGETVARIANT=latest

# STAGE 1 — build base libs
FROM debian:bookworm-slim@${DEBIAN_DIGEST} AS runtime-deps

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
FROM gcr.io/distroless/base-debian12:${TARGETVARIANT}-amd64@${DISTROLESS_DIGEST}

# Hardcoded for amd64 - no conditionals needed!
ARG LIB_DIR=x86_64-linux-gnu
ARG LD_SO=ld-linux-x86-64.so.2

# Copy runtime dependencies
# Copy dynamic linker (required for dynamically linked binaries)
COPY --from=runtime-deps /lib/${LIB_DIR}/${LD_SO} /lib/${LIB_DIR}/${LD_SO}
# Copy shared libraries (libc6, libssl3, libicu72, etc.) - combined into single layer
COPY --from=runtime-deps /usr/lib/${LIB_DIR} /usr/lib/${LIB_DIR}
# Copy SSL certificates and timezone data - combined into single layer
COPY --from=runtime-deps /etc/ssl/certs /etc/ssl/certs
COPY --from=runtime-deps /usr/share/zoneinfo /usr/share/zoneinfo

# Add metadata labels for traceability
LABEL org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${GIT_COMMIT}"

# K8s security default
USER 65532:65532
WORKDIR /app
CMD ["--help"]

