# Distroless Runtime CI Configuration

This branch uses the CI v2 prototype from `runlix/build-workflow@side/ci-v2-prototype`.

## Files

### config.json

`.ci/config.json` is the release-branch source of truth.

Each target is an explicit build unit:

- `stable-amd64`
- `stable-arm64`
- `debug-amd64`
- `debug-arm64`

Each target defines:

- the final manifest tag (`stable` or `debug`)
- one architecture (`amd64` or `arm64`)
- one Dockerfile
- one pinned upstream distroless base reference
- repo-specific build args for the Debian builder image

This base image intentionally omits `version`. It tracks pinned upstream distroless digests rather than an application release number.

### Smoke tests

This base image still has no smoke test. The runtime image provides libraries and filesystem content, not an application process with a stable health endpoint.

That is a deliberate exception in this repo:

- PR validation builds each target
- release builds and publishes each target
- downstream service images validate runtime behavior through their own smoke tests

## CI flow

### PR validation

`pr-validation.yml` now does only four things:

1. checkout the service repository
2. checkout the build-workflow v2 tooling
3. validate `.ci/config.json`
4. build each enabled target locally

### Release

`release.yml` now does only four things:

1. validate `.ci/config.json`
2. build and push one temporary image per target
3. create the `stable` and `debug` manifests
4. upload `release-metadata.json`

The release workflow does not write to `main`. Metadata sync now belongs to `main`.

## Main-branch metadata sync

`main` owns:

- `README.md`
- `links.json`
- `releases.json`
- `renovate.json`
- `.github/workflows/sync-release-metadata.yml`

The `main` workflow consumes `release-metadata.json` from successful release runs and writes `releases.json`.

## Local validation

From a checkout of this branch:

```bash
jq empty .ci/config.json
```

With a checkout of `runlix/build-workflow@side/ci-v2-prototype` available:

```bash
/path/to/build-workflow/prototypes/ci-v2/scripts/validate-config.sh .ci/config.json
```

## Dependency chain

```
gcr.io/distroless/base-debian12
  ↓
ghcr.io/runlix/distroless-runtime
  ↓
ghcr.io/runlix/{transmission,sonarr,sabnzbd,home-assistant,radarr}
```
