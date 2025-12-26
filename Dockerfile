# STAGE 1 — build base libs
FROM docker.io/library/debian:bookworm-slim AS runtime-deps

RUN apt-get update && apt-get install -y --no-install-recommends \
    libc6 \
    libssl3 \
    ca-certificates \
    tzdata \
 && rm -rf /var/lib/apt/lists/*

# STAGE 2 — distroless final image
FROM gcr.io/distroless/base-debian12:debug_amd64

# Copy runtime dependencies
COPY --from=runtime-deps /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu
COPY --from=runtime-deps /etc/ssl/certs /etc/ssl/certs
COPY --from=runtime-deps /usr/share/zoneinfo /usr/share/zoneinfo

# K8s security default
USER 65532:65532
WORKDIR /app
CMD ["--help"]
