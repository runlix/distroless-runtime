# Distroless Runtime CI Configuration

This branch uses the self-contained CI v2 reusable workflows from `runlix/build-workflow` via the temporary preview tag `ci-v2-summary-preview-20260317`.

The canonical CI v2 schema on that branch is still pinned in `.ci/config.json` to commit `2e7c3cf52b52c0f88d5fe16b4c1e85d1162cc2e5`.

## Source of truth

`.ci/config.json` is the only active CI config for this branch.

Each target is an explicit build unit:

- `stable-amd64`
- `stable-arm64`
- `debug-amd64`
- `debug-arm64`

Each target declares:

- the final manifest tag
- one architecture
- one Dockerfile
- one pinned upstream distroless base reference
- repo-specific build args for the Debian builder image

This base image intentionally omits `version`. It tracks pinned upstream distroless digests rather than an application release number.

## Smoke tests

This base image still has no smoke test.

That is deliberate for this repo:

- PR validation builds each target locally
- release builds, pushes, and publishes each target
- downstream service images validate runtime behavior through their own smoke tests

## CI flow

`pr-validation.yml` is a thin trigger wrapper around the shared reusable workflow in `build-workflow`.

The shared PR workflow:

1. validates `.ci/config.json`
2. renders the build matrix
3. builds each enabled target locally
4. emits the final aggregate check `validate / summary`

`release.yml` is a thin trigger wrapper around the shared reusable workflow in `build-workflow`.

The shared release workflow:

1. validates `.ci/config.json`
2. builds each enabled target locally
3. pushes one temporary image per target
4. creates the `stable` and `debug` manifests
5. uploads `release-metadata.json`

The release workflow does not write to `main`. Metadata sync stays on `main`.

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

With a checkout of `runlix/build-workflow` at commit `2e7c3cf52b52c0f88d5fe16b4c1e85d1162cc2e5` available:

```bash
ajv validate --spec=draft2020 \
  -s /path/to/build-workflow/schema/ci-config-v2.schema.json \
  -d .ci/config.json
```

## Dependency chain

```
gcr.io/distroless/base-debian12
  ↓
ghcr.io/runlix/distroless-runtime
  ↓
ghcr.io/runlix/{transmission,sonarr,sabnzbd,home-assistant,radarr}
```
