# Distroless Runtime

`distroless-runtime` publishes the shared runtime base used by Runlix application images.

The current published image name is:

```text
ghcr.io/runlix/distroless-runtime-v2-canary
```

Use the stable manifest tag from the published image:

```dockerfile
FROM ghcr.io/runlix/distroless-runtime-v2-canary:stable
```

The authoritative published tags, digests, and source revision live in [release.json](release.json).

## What’s Included

- `libc6`
- `libssl3`
- `libicu72`
- `ca-certificates`
- `tzdata`

These libraries are copied into a distroless base so downstream images get a minimal runtime layer with the shared dependencies they need.

## Branch Layout

`main` owns metadata and automation config:

- `README.md`
- `links.json`
- `release.json`
- `renovate.json`
- `.github/workflows/validate-release-metadata.yml`

`release` owns build and publish inputs:

- `.ci/build.json`
- `.ci/smoke-test.sh`
- `linux-*.Dockerfile`
- `.github/workflows/validate-build.yml`
- `.github/workflows/publish-release.yml`

## Release Flow

Changes merge to `release`, where `Publish Release` builds the `stable` and `debug` multi-arch manifests, attests them, optionally sends Telegram, and opens the sync PR back to `main`.

`main` validates metadata and config-only changes with `Validate Release Metadata`.

## License

GPL-3.0
