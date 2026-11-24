# Deploy and Host Mongo Express with Railway

Mongo Express is a lightweight web-based admin interface for MongoDB, built with Node.js and Express. This template deploys Mongo Express 1.0 behind a mandatory password login, connected over Railway's private network to a bundled MongoDB 8.0 database, so you can browse collections and edit documents minutes after you deploy.

## About Hosting Mongo Express

Mongo Express is a single Node.js process that talks to MongoDB with a connection string and serves a small web UI. It keeps no data of its own. Hosting it safely is mostly about access: the UI can read, edit and drop everything its MongoDB user can, so it must never be reachable without a login, and the database itself should stay off the internet. This template turns on Mongo Express's HTTP basic auth with a generated password (a missing or weak password never falls back to the built-in default), keeps MongoDB on Railway's private network only, waits for MongoDB at start, and pins both images to exact digests.

## Common Use Cases

- Browse databases and collections of a Railway MongoDB from the browser
- Insert, edit and delete documents with a JSON editor
- Run queries and simple aggregations, add and drop indexes
- Import and export collections as JSON or CSV
- View GridFS files

## Dependencies for Mongo Express Hosting

- Mongo Express web UI (`mongo-express` official image)
- A MongoDB server to manage (bundled: MongoDB 8.0)

### Deployment Dependencies

- Mongo Express source and configuration: https://github.com/mongo-express/mongo-express
- Mongo Express Docker image: https://hub.docker.com/_/mongo-express
- MongoDB 8.0 manual: https://www.mongodb.com/docs/manual/
- Railway private networking: https://docs.railway.com/guides/private-networking

### Implementation Details

| Service | Image | Purpose | Public |
|---|---|---|---|
| Mongo Express | `mongo-express:1.0.2-20-alpine3.19` (digest-pinned) | Web UI on port 8081, basic auth | HTTPS domain |
| MongoDB | `mongo:8.0.38` (digest-pinned) | Database, volume `/data/db` | No (private network only) |

**First login**: open the Mongo Express service → Variables, copy `ME_CONFIG_BASICAUTH_USERNAME` (default `admin`) and `ME_CONFIG_BASICAUTH_PASSWORD`, open the public domain and enter them when the browser asks. To rotate the password, change the variable and redeploy. If the password is empty or shorter than 8 characters, the start log says so and the login is locked with a random password until you set a valid one; the deploy never falls back to a default password.

**Manage another MongoDB** (same project): set `ME_CONFIG_MONGODB_URL` on Mongo Express to that database's private URL, for example `${{MongoDB.MONGO_URL}}` or `mongodb://{user}:{password}@{service}.railway.internal:27017/?authSource=admin`, then redeploy. For a database user without admin rights, include the database name in the URL and set `ME_CONFIG_MONGODB_ENABLE_ADMIN=false`. Replica-set URLs (several hosts) work too. A database in another project or provider needs its TCP proxy host and port (or `mongodb+srv://` for Atlas). You can delete the bundled MongoDB service if you only manage other databases.

**Connect your apps to the bundled MongoDB**: reference `${{MongoDB.MONGO_URL}}` in your app's variables. MongoDB has no public port; enable a TCP proxy on the MongoDB service to reach it from outside Railway.

**Read-only mode**: set `ME_CONFIG_OPTIONS_READONLY=true` to hide every write action, useful for production data.

**Scaling and upgrades**: Mongo Express is stateless and light; one replica is plenty. To upgrade, change the image tag and digest in the service settings. MongoDB minor updates (8.0.x) are drop-in; a major upgrade (8.0 → 9.0) needs `setFeatureCompatibilityVersion` steps from the MongoDB manual, so take a `mongodump` first.

**Good to know**: Mongo Express 1.0.2 is the latest stable release and the project changes slowly; use it as an admin tool behind its login, not as an app for end users. Basic auth sends the password with every request, which is safe here because Railway serves the domain over HTTPS only. This is a community template and is not affiliated with the Mongo Express project or MongoDB, Inc.

### Why Deploy Mongo Express on Railway?

Railway runs Mongo Express and MongoDB side by side on a private network with a persistent volume, HTTPS and logs handled for you. One click gives you a working MongoDB plus a password-protected browser admin for it, and the same UI can be pointed at the other MongoDB services in your project.
