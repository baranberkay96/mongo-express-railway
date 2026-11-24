# Mongo Express 1.0 with MongoDB 8.0: Railway template spec

## Listing

| Field | Value |
|---|---|
| Name | **Mongo Express 1.0 with MongoDB 8.0** |
| Description | MongoDB web admin behind a password login, plus a ready MongoDB 8.0. (68 chars) |
| Category | Storage |
| Tags | mongo-express, mongodb, mongo, database, admin, gui, nosql |
| Icon | `https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/mongodb.svg` |
| Repo | `baranberkay96/mongo-express-railway` (source of the start command; both services run official images) |

## Base market templates (checked 2026-11-24)

| Code | Name | Total deploys | Stack | Problems |
|---|---|---|---|---|
| `P7J0lk` | Mongo Express | 224 | `mongo:7`, `mongo-express:1` | MongoDB **public TCP proxy** and Mongo Express connecting through it; floating tags; empty/short password would fall back to `pass` |
| `mongo-express-ui` | Mongo Express | 1 | `mongo:8.0`, third-party repo build | Unpinned third-party repo |

Kept: official `mongo-express` image with basic auth and `/status` healthcheck; Railway's MongoDB service definition and variable names.

## Improvements over market templates

1. **Login can never fall back to `admin`/`pass`**: basic auth forced on; an empty/short/overlong password locks the login with a random one and logs how to fix it (STANDARD 8.29).
2. **MongoDB private only** (no TCP proxy); Mongo Express connects over `mongodb.railway.internal`.
3. **Pinned digests** (mongo-express 1.0.2, MongoDB 8.0.38).
4. Generated cookie/session secrets (the image default is the literal `secret`).
5. Waits up to 300 s for MongoDB (services start in parallel); dual-stack listener.

## Pinned versions

| Service | Source | Version | Checked |
|---|---|---|---|
| Mongo Express | `mongo-express:1.0.2-20-alpine3.19@sha256:1aae0077…d550` | 1.0.2 (latest stable; v1.1.0 only as release candidates) | 2026-11-24 |
| MongoDB | `mongo:8.0.38@sha256:479e85ce…5d01` | 8.0.38 | 2026-11-24 |

## Services

### Mongo Express

- Official image, start command from `services/mongo-express/me-start.sh` (joined by `services/to-template.py`), ends with `/sbin/tini -- /docker-entrypoint.sh mongo-express`.
- Public domain, `targetPort` 8081, `PORT=8081`, healthcheck `/status` (served before the auth middleware), 300 s, restart `ON_FAILURE` ×10. Stateless.

### MongoDB

- Official image, `docker-entrypoint.sh mongod --ipv6 --bind_ip ::,0.0.0.0 --setParameter diagnosticDataCollectionEnabled=false` (Railway's MongoDB command).
- Volume `/data/db`, private only, restart `ON_FAILURE` ×10, 60 s draining. No healthcheck (no HTTP); Mongo Express's `/status` is the template's health target.

## Resource estimate

Measured on the test deploy (2026-11-24, idle after logins, creating a database/collection/document): Mongo Express 50-85 MiB, MongoDB 270-450 MiB (WiredTiger sizes its cache from the container limit; on a small plan it stays far lower), CPU < 0.01 vCPU.

| Service | Idle RAM | Typical RAM | CPU |
|---|---|---|---|
| Mongo Express | 60 MB | 80-150 MB | < 0.01 idle |
| MongoDB | 270 MB | 300 MB-1 GB (cache grows with data) | 0.01-0.3 |

Estimated cost: idle ≈ $3.5/month (0.33 GB RAM + ~0.5 GB volume); typical ≈ $5-12/month. Minimum plan: **Trial** runs it (both under 1 GB; MongoDB's cache adapts to the limit). Hobby recommended for real data.

## Verification checklist

- [x] Both services SUCCESS; `/status` 200 without auth (health only).
- [x] `/` without credentials and with a wrong password → 401; with the generated credentials → 200, databases listed.
- [x] Created database `handson`, collection `notes`, inserted a document; visible in the collection view; server version 8.0.38 shown (Node driver 4.x works with MongoDB 8.0).
- [x] `ME_CONFIG_BASICAUTH_PASSWORD=abc` (STANDARD 8.29): deploy SUCCESS, warning logged, `abc` rejected (401) — the login never falls back to `pass`.
- [x] Mongo Express and MongoDB redeployed at the same time: the first version (image's wait loop) hung ~2 min on a stale address; the template's own wait (3 s per attempt) came up at once. Data persisted across the MongoDB redeploy.
- [ ] Post-publish deploy by the real template id (`ship.py publish`).

## Open questions

- The `mongo-express:1.0.2` image was built 2024-11-21 on Node 20 / Alpine 3.19 (Alpine 3.19 is past its support window). It is still the latest stable image; revisit when v1.1.0 is released.
- mongo-express's Node driver (4.x) predates MongoDB 8.0; checked by hand on the test deploy (see checklist).
