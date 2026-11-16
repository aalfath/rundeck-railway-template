# Rundeck on Railway

A Railway template for [Rundeck](https://www.rundeck.com/open-source), the open-source runbook automation and job scheduler from PagerDuty. It builds from this repo: the `Dockerfile` pins the official image and adds a small start script.

- **Rundeck:** 6.3.0 (`rundeck/rundeck:6.3.0@sha256:9b0477556ec3476afab498708b996cbd3373e87b3b3a1447790dadead21db521`)
- **Database:** Railway Postgres (jobs, execution history, project config, encrypted key storage)
- **Volume:** `/home/rundeck/var` (execution log files and local working files)

## What the template deploys

| Service | Source | Notes |
|---|---|---|
| Rundeck | this repo | Public on port 4440 with a Railway domain, health check `/user/login` |
| Postgres | Railway Postgres | Private network only |

## Variables

| Variable | Default | What it does |
|---|---|---|
| `RUNDECK_ADMIN_USER` | `admin` | Admin login name |
| `RUNDECK_ADMIN_PASSWORD` | generated secret | Admin password. Read it in the Rundeck service's **Variables** tab. No `,` or `:` |
| `RUNDECK_ENCRYPTION_PASSWORD` | generated secret | Encrypts key storage and project config in the database. Never change it after first start, or stored keys can't be read |
| `RUNDECK_GRAILS_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Public URL Rundeck uses in links and redirects. Change it if you add a custom domain |
| `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD` | references to Postgres | Database connection |
| `PORT` | `4440` | Port Rundeck listens on |

The start script (`start.sh`):

1. replaces the image's default `admin:admin` and `user:user` logins with `RUNDECK_ADMIN_USER` / `RUNDECK_ADMIN_PASSWORD`, and refuses to start without a password;
2. points Rundeck at Postgres, turns on key storage encryption, and trusts Railway's `X-Forwarded-*` headers;
3. hands the volume to the `rundeck` user, then runs the image's own entrypoint as that user.

Any other `RUNDECK_*` setting from the [Rundeck Docker docs](https://docs.rundeck.com/docs/administration/configuration/docker.html) (SMTP, LDAP, plugins) can be added as a variable on the Rundeck service.

## More users

The template creates one admin. To add users, use LDAP or SSO through `RUNDECK_JAAS_*` variables, or extend `start.sh` in a fork to write more lines to `realm.properties`.

## Updates

Railway notifies everyone who deployed this template when a change is merged to `main` here, and each deployer chooses when to apply it. Every version change is listed in [`CHANGELOG.md`](CHANGELOG.md), breaking changes first. Rundeck runs its own database migrations on start, so take a Postgres backup before applying a major-version update.

## Local test

`docker compose -f docker-compose.test.yml up --build` starts Rundeck on http://localhost:44279 with a local Postgres (login `admin` / `localTestPassword123`). It's for testing only.
