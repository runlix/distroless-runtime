# Distroless Runtime CI Configuration

This branch uses CI v2 reusable workflows exported from `runlix/build-workflow`, pinned to commit `83f522fecbdd77b7875e4e474ddbdc78d978ac3e`.

## Files

### config.json

`.ci/config.json` is the active release-branch source of truth for the v2 workflows.

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

### docker-matrix.json

`.ci/docker-matrix.json` is retained temporarily during the transition to CI v2.

It is kept for PR safety and rollback comfort while the new flow is being proven, but the v2 workflows do not read it. Until v2 is accepted, keep it aligned with `.ci/config.json`.

### Smoke tests

This base image still has no smoke test. The runtime image provides libraries and filesystem content, not an application process with a stable health endpoint.

That is a deliberate exception in this repo:

- PR validation builds each target
- release builds and publishes each target
- downstream service images validate runtime behavior through their own smoke tests

## CI flow

### PR validation

`pr-validation.yml` is now a thin trigger wrapper around the shared reusable workflow in `build-workflow`.

The shared workflow:

1. validates `.ci/config.json`
2. checks that the legacy `.ci/docker-matrix.json` still parses cleanly during rollout
3. renders the build matrix
4. builds each enabled target locally

### Release

`release.yml` is now a thin trigger wrapper around the shared reusable workflow in `build-workflow`.

The shared workflow:

1. validates `.ci/config.json`
2. builds and pushes one temporary image per target
3. creates the `stable` and `debug` manifests
4. uploads `release-metadata.json`

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
jq empty .ci/docker-matrix.json
```

With a checkout of `runlix/build-workflow` at commit `83f522fecbdd77b7875e4e474ddbdc78d978ac3e` available:

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
