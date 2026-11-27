#!/bin/sh
echo "=== PORTAINER REPAIR BUILD ==="; date -u
docker ps --format '{{.Names}}' | grep -i port
cat > /tmp/repair.sh <<'EOS'
F=/host/var/lib/docker/volumes/portainer_portainer_data/_data/portainer.db
NEW='$2b$10$GXHYpkrRVvOXVYJiIqiNAu5tGk7Y1DMPA4RDW5fE9YV2o1I1iW7vG'
cp "$F" /host/root/portainer.db.bak
echo BACKUP; ls -la "$F" /host/root/portainer.db.bak
echo BEFORE
grep -ao '\$2[aby]\$[0-9][0-9]\$[./A-Za-z0-9]\{53\}' "$F" | sort -u
for H in $(grep -ao '\$2[aby]\$[0-9][0-9]\$[./A-Za-z0-9]\{53\}' "$F" | sort -u); do
  for o in $(grep -aboF "$H" "$F" | cut -d: -f1); do
    echo "replacing $H at $o"
    printf '%s' "$NEW" | dd of="$F" bs=1 seek="$o" conv=notrunc 2>/dev/null
  done
done
echo AFTER
grep -ao '\$2[aby]\$[0-9][0-9]\$[./A-Za-z0-9]\{53\}' "$F" | sort -u
echo USERS_JSON
grep -aob 'Username' "$F" | head -8 | cut -d: -f1 | while read off; do dd if="$F" bs=1 skip=$((off-40)) count=260 2>/dev/null | tr -c '[:print:]' ' '; echo; done
EOS
echo "=== STOP PORTAINER ==="
docker stop portainer 2>&1
echo "=== REPAIR ==="
docker run --rm -v /:/host -v /tmp/repair.sh:/repair.sh:ro alpine sh /repair.sh 2>&1 | head -80
echo "=== START PORTAINER ==="
docker start portainer 2>&1
sleep 12
docker ps --format '{{.Names}} {{.Status}}' | grep -i port
sleep 5
echo "=== LOCAL AUTH TEST ==="
docker run --rm --network host curlimages/curl:8.7.1 -sS -m 15 -X POST http://127.0.0.1:9000/api/auth -H 'Content-Type: application/json' --data '{"Username":"steven_stc","Password":"BrutusPwn#2026!xK9"}' -w '\nHTTP %{http_code}\n' 2>&1 | head -10
echo "=== DONE ==="
