# Distroless Runtime CI Configuration

This branch uses the clean v2 reusable workflows from `runlix/build-workflow` pinned to full commit SHA `d9330ebad6233b71595ced05367fc7773c07c087`.

The canonical CI schema in `.ci/config.json` is pinned to the same full SHA.

## Source of truth

`.ci/config.json` is the only active CI config for this branch.

Each target is an explicit build unit:

- `stable-amd64`
- `stable-arm64`
- `debug-amd64`
- `debug-arm64`

Each target declares:

- the final manifest tag
- one platform
- one Dockerfile
- one pinned distroless base reference
- one pinned Debian builder reference

This base image intentionally omits `version`. It tracks pinned upstream distroless digests rather than an application release number.

## Smoke tests

This base image now runs `.ci/smoke-test.sh` for every target.

Because distroless images do not include a shell and this repo publishes a runtime base rather than an application image, the smoke test stays intentionally small:

- verify the image exists locally
- verify the default `USER` and `WORKDIR`
- execute the architecture-specific dynamic linker already present in the image

That gives us a real `docker run` check without inventing an application command that this image does not own.

## CI flow

`validate.yml` is a thin trigger wrapper around the shared reusable workflow in `build-workflow`.

The shared validate workflow:

1. validates `.ci/config.json`
2. renders the build matrix
3. builds each enabled target locally
4. runs the target test when configured
5. emits the final aggregate check `validate / summary`

`release.yml` is a thin trigger wrapper around the shared reusable workflow in `build-workflow`.

The shared release workflow:

1. validates `.ci/config.json`
2. builds each enabled target locally
3. runs the target test when configured
4. pushes one temporary image per target
5. creates the `stable` and `debug` manifests
6. uploads `release-record.json` as artifact `release-record`

The release workflow does not write to `main`. Record sync stays on `main`.

## Main-branch record sync

`main` owns:

- `README.md`
- `links.json`
- `release.json`
- `renovate.json`
- `.github/workflows/sync-release-record.yml`

The `main` workflow filters on `workflow_run.branches: [release]`, consumes `release-record.json` from successful release runs, and writes `release.json`.

## Local validation

From a checkout of this branch:

```bash
docker run --rm \
  -v "$PWD:/workspace" \
  -w /workspace \
  ghcr.io/runlix/build-workflow-tools:ci \
  validate-config .ci/config.json
```

## Dependency chain

```
gcr.io/distroless/base-debian12
  ↓
ghcr.io/runlix/distroless-runtime
  ↓
ghcr.io/runlix/{transmission,sonarr,sabnzbd,home-assistant,radarr}
```
