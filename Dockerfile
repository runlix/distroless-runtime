# STAGE 1 — build base libs
FROM docker.io/library/debian:bookworm-slim AS runtime-deps

RUN apt-get update && apt-get install -y --no-install-recommends \
    # <Add_package_for_base_image> \
 && rm -rf /var/lib/apt/lists/*

# STAGE 2 — distroless final image
FROM gcr.io/distroless/base-debian12

# Copy runtime dependencies
# Example:
# COPY --from=runtime-deps /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu


# K8s security default
USER 65532:65532
WORKDIR /app
CMD ["--help"]
