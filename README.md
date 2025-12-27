# Distroless Runtime

Base Docker image.

## What's Included

- libc6 - Standard C library (required for .NET binaries)
- libssl3 - SSL/TLS library (required for HTTPS operations)
- libicu72 - International Components for Unicode (required for .NET globalization)
- ca-certificates - Certificate authority certificates (for HTTPS/TLS support)
- tzdata - Timezone data

## Usage

```dockerfile
FROM ghcr.io/runlix/distroless-runtime:release
```

## Tags

See [tags.json](tags.json) for available tags.

## License

GPL-3.0
