# Distroless Runtime CI Configuration

This directory contains configuration for the CI/CD pipeline.

## Files

### docker-matrix.json

Defines the build matrix for multi-architecture Docker images. See the [schema documentation](https://github.com/runlix/build-workflow/blob/main/schema/docker-matrix-schema.json) for details.

**Variants:**
- `default-amd64` - Standard runtime base for AMD64 (minimal, no shell)
- `default-arm64` - Standard runtime base for ARM64 (minimal, no shell)
- `debug-amd64` - Debug runtime base for AMD64 (includes shell and debugging tools)
- `debug-arm64` - Debug runtime base for ARM64 (includes shell and debugging tools)

**Base Image:**
This image wraps `gcr.io/distroless/base-debian12` and adds common runtime dependencies needed by application services:
- libc6
- libssl3
- libicu72
- ca-certificates
- tzdata

**No Application Version:**
Unlike application services, this base image does not have a `version` field in docker-matrix.json because it tracks the upstream distroless base rather than a specific application release.

### Smoke Tests

This base image intentionally has no smoke tests (`test_script` is empty). Base runtime images provide libraries and runtime environments but don't run standalone applications that can be tested.

Application services that consume this base image (transmission, sonarr, home-assistant, etc.) have their own comprehensive smoke tests that indirectly validate the runtime base.

## Testing Changes

Before committing changes to this configuration:

1. **Validate JSON syntax**:
   ```bash
   jq . docker-matrix.json
   ```

2. **Validate against schema**:
   ```bash
   curl -sL https://raw.githubusercontent.com/runlix/build-workflow/main/schema/docker-matrix-schema.json \
     > /tmp/schema.json
   ajv validate -s /tmp/schema.json -d docker-matrix.json
   ```

3. **Build locally** (requires Docker):
   ```bash
   # Build for current architecture
   docker build -f linux-amd64.Dockerfile \
     --build-arg BUILDER_IMAGE=docker.io/library/debian \
     --build-arg BUILDER_TAG=bookworm-slim \
     --build-arg BUILDER_DIGEST=sha256:... \
     --build-arg BASE_IMAGE=gcr.io/distroless/base-debian12 \
     --build-arg BASE_TAG=latest-amd64 \
     --build-arg BASE_DIGEST=sha256:... \
     -t distroless-runtime:test .
   ```

4. **Verify image contents**:
   ```bash
   # Use debug variant to inspect
   docker run --rm -it ghcr.io/runlix/distroless-runtime:debug sh
   ```

## Workflow Integration

The build workflow automatically:

1. **On Pull Requests**: Builds all variants for validation
2. **On Merges to Release Branch**: Rebuilds from release branch and pushes to registry
3. **After Build**: Creates multi-arch manifests tagged as `stable` or `debug`

Application services depend on this base image and reference it in their docker-matrix.json:
```json
"BASE_IMAGE": "ghcr.io/runlix/distroless-runtime",
"BASE_TAG": "stable",
"BASE_DIGEST": "sha256:..."
```

Renovate automatically updates the BASE_DIGEST when new distroless-runtime versions are published.

## Dependency Chain

```
gcr.io/distroless/base-debian12
  ↓
ghcr.io/runlix/distroless-runtime
  ↓
ghcr.io/runlix/{transmission,sonarr,sabnzbd,home-assistant,radarr}
```

See [build-workflow documentation](https://github.com/runlix/build-workflow/tree/main/docs) for more details.
