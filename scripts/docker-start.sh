#!/bin/sh
set -e

# Wrapper used as the Docker CMD for the Paperclip Coolify deployment.
# It generates the Paperclip config from environment variables, starts the
# server, waits for it to be healthy, and then creates the bootstrap CEO
# invite so the first admin can claim the instance without running
# `paperclipai onboard` interactively.

: "${PAPERCLIP_HOME:=/paperclip}"
: "${PAPERCLIP_INSTANCE_ID:=default}"
: "${PAPERCLIP_CONFIG:=$PAPERCLIP_HOME/instances/$PAPERCLIP_INSTANCE_ID/config.json}"
: "${HOST:=0.0.0.0}"
: "${PORT:=3100}"

export PAPERCLIP_HOME PAPERCLIP_INSTANCE_ID PAPERCLIP_CONFIG HOST PORT

# 1. Generate config.json, local .env, and secrets key from environment variables.
node /usr/local/bin/paperclip-init.mjs

# 2. Start the Paperclip server in the background.
# The upstream CMD is used so behaviour matches a plain Paperclip server start.
node --import ./server/node_modules/tsx/dist/loader.mjs server/dist/index.js &
SERVER_PID=$!

# 3. Wait for the server to report healthy.
HEALTH_URL="http://localhost:${PORT}/api/health"
START_TIME=$(date +%s)
TIMEOUT=180

printf '[docker-start] waiting for Paperclip server at %s...\n' "$HEALTH_URL"
while true; do
  if wget -qO- "$HEALTH_URL" >/dev/null 2>&1; then
    printf '[docker-start] Paperclip server is healthy\n'
    break
  fi

  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    printf '[docker-start] server process exited unexpectedly\n' >&2
    wait "$SERVER_PID" || true
    exit 1
  fi

  NOW=$(date +%s)
  if [ $((NOW - START_TIME)) -gt "$TIMEOUT" ]; then
    printf '[docker-start] timed out waiting for server health after %ss\n' "$TIMEOUT" >&2
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" || true
    exit 1
  fi

  sleep 2
done

# 4. Create the bootstrap CEO invite. The CLI needs PAPERCLIP_CONFIG set so it
# can find the config we just generated. The bootstrap command uses DATABASE_URL
# from the environment/config to connect directly to Postgres.
printf '[docker-start] creating bootstrap CEO invite...\n'
paperclipai auth bootstrap-ceo || true

# 5. Keep the container alive on the server process.
wait "$SERVER_PID"
