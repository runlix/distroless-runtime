# Distroless Runtime

Base Docker image providing essential runtime libraries for applications. 
This image extends Google's distroless base with required shared libraries and is used as the foundation for all Runlix application images.

## Purpose

The `distroless-runtime` image serves as the base layer for all application images in the Runlix ecosystem. It provides a minimal, secure runtime environment with only the essential libraries needed for applications to run.

## What's Included

- libc6 - Standard C library (required for binaries)
- libssl3 - SSL/TLS library (required for HTTPS operations)
- libicu72 - International Components for Unicode (required for globalization)
- ca-certificates - Certificate authority certificates (for HTTPS/TLS support)
- tzdata - Timezone data

## Usage

```dockerfile
FROM ghcr.io/runlix/distroless-runtime:release-latest
```

## Tags

See [tags.json](tags.json) for available tags.

## License

GPL-3.0
