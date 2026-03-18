# Distroless Runtime CI Configuration

This branch uses the self-contained CI v2 reusable workflows from `runlix/build-workflow` pinned to full commit SHA `2b85050ee48a849e72e38eca7039ee9054d0f5d3`.

The canonical CI v2 schema in `.ci/config.json` is pinned to the same full SHA.

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
4. runs the target test when configured
5. emits the final aggregate check `validate / summary`

The wrapper intentionally triggers on `.ci/*.sh` and `.dockerignore` so shell build helpers and ignore-file changes are treated as build inputs.

`release.yml` is a thin trigger wrapper around the shared reusable workflow in `build-workflow`.

The shared release workflow:

1. validates `.ci/config.json`
2. builds each enabled target locally
3. runs the target test when configured
4. pushes one temporary image per target
5. creates the `stable` and `debug` manifests
6. uploads `release-metadata.json` as artifact `release-metadata`

The release workflow does not write to `main`. Metadata sync stays on `main`.

## Main-branch metadata sync

`main` owns:

- `README.md`
- `links.json`
- `releases.json`
- `renovate.json`
- `.github/workflows/sync-release-metadata.yml`

The `main` workflow filters on `workflow_run.branches: [release]`, consumes `release-metadata.json` from successful release runs, and writes `releases.json`.

## Local validation

From a checkout of this branch:

```bash
jq empty .ci/config.json
```

With a checkout of `runlix/build-workflow` at commit `2b85050ee48a849e72e38eca7039ee9054d0f5d3` available:

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
