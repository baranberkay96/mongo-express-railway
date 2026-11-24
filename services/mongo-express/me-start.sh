#!/bin/bash
# Readable source of the Mongo Express service's start command. Nothing is
# built from this folder: the service runs the official image
# (mongo-express:1.0.2-20-alpine3.19) and template.json carries this script
# joined into one line:
#
#   /bin/bash -c '<this script>' me-start
#
# Regenerate it with `python3 ../to-template.py --write`. One-line rules: no
# single quotes, no backslashes, comments on their own lines, every line
# complete or ending in then/do/else.
#
# Railway's start command replaces the image ENTRYPOINT (tini + the image's
# /docker-entrypoint.sh), so the script ends by exec-ing that entrypoint.
# Before it, the script makes the login mandatory and safe (STANDARD 8.29):
#   - basic auth is always on (ME_CONFIG_BASICAUTH=true);
#   - an empty, shorter than 8 or longer than 128 character password would
#     fall back to mongo-express's built-in "pass"; instead the login is locked
#     with a random password nobody knows, and the log says how to fix it;
#   - an empty user name becomes "admin";
#   - a non-numeric PORT becomes 8081.
# It also waits up to ME_CONFIG_CONNECT_RETRIES attempts (about 4 s each,
# default 300) for MongoDB, because services start in parallel on Railway.
# Each attempt has a 3 s timeout: the image's own wait loop has none, and a
# connect to the address of a MongoDB that is being redeployed hung for over
# two minutes on Railway. After the wait it starts mongo-express the way the
# image's /docker-entrypoint.sh does (tini + node app in /app).
set -e
export ME_CONFIG_BASICAUTH=true
U="${ME_CONFIG_BASICAUTH_USERNAME:-}"
if [ -z "$U" ]; then
echo "me-start: ME_CONFIG_BASICAUTH_USERNAME is empty, using admin"
export ME_CONFIG_BASICAUTH_USERNAME=admin
fi
P="${ME_CONFIG_BASICAUTH_PASSWORD:-}"
if [ ${#P} -lt 8 ] || [ ${#P} -gt 128 ]; then
echo "me-start: WARNING ME_CONFIG_BASICAUTH_PASSWORD must be 8-128 characters (got ${#P}). The login is locked with a random password."
echo "me-start: Fix: set ME_CONFIG_BASICAUTH_PASSWORD to 8-128 characters and redeploy."
export ME_CONFIG_BASICAUTH_PASSWORD="$(head -c 48 /dev/urandom | base64 | tr -dc A-Za-z0-9 | head -c 40)"
fi
unset P
case "${PORT:-}" in ""|*[!0-9]*) echo "me-start: PORT=${PORT:-} is not a number, using 8081"; export PORT=8081 ;; esac
export ME_CONFIG_CONNECT_RETRIES="${ME_CONFIG_CONNECT_RETRIES:-300}"
case "$ME_CONFIG_CONNECT_RETRIES" in ""|*[!0-9]*) export ME_CONFIG_CONNECT_RETRIES=300 ;; esac
W="${ME_CONFIG_MONGODB_URL:-}"
H=""
case "$W" in *,*|mongodb+srv:*|"") ;; *) W=${W#*://}; W=${W%%/*}; W=${W%%[?]*}; W=${W##*@}; H=${W%:*}; P=${W##*:} ;; esac
if [ "$H" = "$W" ]; then P=27017; fi
case "${P:-}" in ""|*[!0-9]*) P=27017 ;; esac
N=0
if [ -n "$H" ]; then
echo "me-start: waiting for $H:$P"
until timeout 3 bash -c "exec 6<>/dev/tcp/$H/$P" 2>/dev/null; do
N=$((N + 1))
if [ $N -ge $ME_CONFIG_CONNECT_RETRIES ]; then
echo "me-start: $H:$P still unreachable after $N attempts, starting anyway"
break
fi
sleep 1
done
fi
echo "me-start: basic auth on (user $ME_CONFIG_BASICAUTH_USERNAME), listening on ${VCAP_APP_HOST:-0.0.0.0}:$PORT"
cd /app
exec /sbin/tini -- node app
