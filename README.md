# Distroless Runtime

Base Docker image containing runtime dependencies for media services (Sonarr, Radarr, etc.).

## What's Included

- ffmpeg - Video/audio processing
- mediainfo - Media metadata extraction
- sqlite3 - Database engine
- libssl3, libc6 - Required for .NET binaries
- ca-certificates - HTTPS/TLS support
- tzdata - Timezone data

## Usage

```dockerfile
FROM ghcr.io/runlix/distroless-runtime:release
```

## Branch Structure

- **`main` branch**: Contains metadata files (README.md, links.json, tags.json, call-build.yml)
- **`release` branch**: Contains Dockerfile and build-related files

## Tags

See [tags.json](tags.json) for available tags.

## License

GPL-3.0
