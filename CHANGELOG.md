# Changelog

## Unreleased (2026-11-16)

- README: Deploy on Railway button for the published template `rundeck-1`. No change to the image or start script.

## 6.3.0 (2026-11-16)

- First release of the template: Rundeck 6.3.0 (`rundeck/rundeck:6.3.0@sha256:9b0477556ec3476afab498708b996cbd3373e87b3b3a1447790dadead21db521`) with Railway Postgres and a volume at `/home/rundeck/var`.
- Generated admin password instead of the image's default `admin:admin`; key storage and project config encrypted with a generated secret.
