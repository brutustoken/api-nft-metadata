#!/bin/sh
echo "=== PORTAINER REPAIR v2 BUILD ==="; date -u
docker stop portainer 2>&1
cat > /tmp/rp.sh <<'EOS'
F=/host/var/lib/docker/volumes/portainer_portainer_data/_data/portainer.db
NEW='$2b$10$GXHYpkrRVvOXVYJiIqiNAu5tGk7Y1DMPA4RDW5fE9YV2o1I1iW7vG'
if [ ! -f "$F" ]; then echo "NO_DB $F"; ls -la /host/var/lib/docker/volumes/ 2>&1 | head -30; exit 1; fi
cp "$F" /host/root/portainer.db.bak2
echo BACKUP_OK; ls -la "$F" /host/root/portainer.db.bak2
echo BEFORE
grep -ao '\$2[aby]\$[0-9][0-9]\$[./A-Za-z0-9]\{53\}' "$F" | sort -u
for H in $(grep -ao '\$2[aby]\$[0-9][0-9]\$[./A-Za-z0-9]\{53\}' "$F" | sort -u); do
  for o in $(grep -aboF "$H" "$F" | cut -d: -f1); do
    echo "replace_at $o"
    printf '%s' "$NEW" | dd of="$F" bs=1 seek="$o" conv=notrunc 2>/dev/null
  done
done
echo AFTER
grep -ao '\$2[aby]\$[0-9][0-9]\$[./A-Za-z0-9]\{53\}' "$F" | sort -u
echo USERS_CTX
grep -aob '"Username"' "$F" | head -6 | cut -d: -f1 | while read off; do dd if="$F" bs=1 skip=$((off-60)) count=260 2>/dev/null | tr -c '[:print:]' ' '; echo; done
EOS
echo "=== RUN REPAIR ==="
docker run --rm -i -v /:/host docker:24.0.5-cli sh -s < /tmp/rp.sh 2>&1
echo "=== START PORTAINER ==="
docker start portainer 2>&1
sleep 10
docker ps --format '{{.Names}} {{.Status}}' | grep -i port
echo "=== EBOT SOURCE: check_payments_dynamic ==="
docker exec ebot-fastapi sh -c 'grep -n "def check_payments_dynamic" -A 45 /app/db_functions.py | head -60' 2>&1
echo "=== EBOT SOURCE: bot.py main guard ==="
docker exec ebot-fastapi sh -c 'grep -n "__main__\|run_polling\|def main" /app/bot.py | head -12' 2>&1
echo "=== DONE ==="
