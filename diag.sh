#!/bin/sh
echo "=== ID/HOST ==="
id; hostname; uname -a
echo "=== DOCKER VERSION ==="
docker version || true
echo "=== PS ==="
docker ps -a --format '{{.Names}} | {{.Image}} | {{.Status}} | {{.Ports}}' || true
echo "=== ENVS ==="
for c in $(docker ps -q); do
  echo "--- $(docker inspect -f '{{.Name}}' $c)"
  docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' $c
 done
echo "=== COMPOSE DIRS ==="
docker ps -a --format '{{.Label "com.docker.compose.project.working_dir"}}' | sort -u
echo "=== HOST ROOT ==="
docker run --rm -v /:/host alpine:3.20 sh -c 'ls -la /host | head -40; cat /host/etc/hostname' || true
echo "=== DONE ==="
