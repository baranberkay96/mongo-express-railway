# NOTICE: Mongo Express template

## Software deployed

| Component | Licence | Source |
|---|---|---|
| Mongo Express 1.0.2 | MIT (© the Mongo Express contributors) | https://github.com/mongo-express/mongo-express, official image `mongo-express:1.0.2-20-alpine3.19`, used unmodified |
| MongoDB Community Server 8.0 | Server Side Public License (SSPL) v1 | official image `mongo:8.0.38`, used unmodified |

The SSPL's extra conditions apply to offering MongoDB itself as a service to third parties. Running MongoDB as your own application's database, as this template does, is ordinary use.

## Written for this template

- `services/mongo-express/me-start.sh`, `services/to-template.py`, `template.json`, `README.md`, `TEMPLATE.md`, this file. MIT, © 2026 the template author.
- Nothing is built: both services run the official images; template.json carries `me-start.sh` as the Mongo Express start command, which ends by running the image's own `tini` + `/docker-entrypoint.sh`.

## Upstream sources checked (2026-11-24, read only; nothing was executed locally)

- `mongo-express/mongo-express` at tag `v1.0.2`: `config.default.js` (environment variables, basic-auth default user/password `admin`/`pass` when unset), `lib/router.js` (health path before the auth middleware), `app.js` (listen address, exit on connection failure).
- `mongo-express/mongo-express-docker`: `Dockerfile.template`, `docker-entrypoint.sh` (TCP wait loop, `ME_CONFIG_CONNECT_RETRIES`).
- Docker Hub index digests of both images; Railway's MongoDB base service (`_railway-base/mongo.json`).

## Market templates reviewed

`P7J0lk` (Mongo Express), `mongo-express-ui`: read for topology and variables only. Nothing was copied.

## Names and affiliation

MongoDB is a trademark of MongoDB, Inc. This is a community template, not affiliated with or endorsed by MongoDB, Inc. or the Mongo Express project.
