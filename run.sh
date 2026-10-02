#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

# Delete only this homework's containers; keep the named data volume.
for container_name in klimov-01-web klimov-01-db; do
  if docker container inspect "$container_name" >/dev/null 2>&1; then
    docker rm -f -v "$container_name"
  fi
done

docker build --progress=plain --build-arg VERSION=2.0 -t klimov-01/probe:2.0 .
docker volume create klimov-01-data

docker run -d --name klimov-01-db \
  -p 8005:5432 \
  -e POSTGRES_PASSWORD=lab -e POSTGRES_DB=lab \
  -v klimov-01-data:/var/lib/postgresql/data \
  postgres:16-alpine

docker run -d --name klimov-01-web \
  -p 8003:5001 \
  --add-host host.docker.internal:host-gateway \
  -e APP_PORT=5001 -e MARKER=sitelab \
  -e DATABASE_URL=postgresql://postgres:lab@host.docker.internal:8005/lab \
  klimov-01/probe:2.0

SECONDS=0
until curl -sf -m 3 localhost:8003/notes >/dev/null || [ "$SECONDS" -ge 60 ]; do
  sleep 2
done
curl -fsS -m 3 localhost:8003/notes
printf '\n'
