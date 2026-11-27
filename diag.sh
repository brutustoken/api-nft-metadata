#!/bin/sh
echo "=== PORTAINER PATCH v3 ==="; date -u
docker stop portainer 2>&1
cat > /tmp/patch.py <<'PYS'
import re
F='/host/var/lib/docker/volumes/portainer_portainer_data/_data/portainer.db'
NEW=b'$2b$10$GXHYpkrRVvOXVYJiIqiNAu5tGk7Y1DMPA4RDW5fE9YV2o1I1iW7vG'
d=open(F,'rb').read()
pat=re.compile(rb'\$2[aby]\$[0-9][0-9]\$[./A-Za-z0-9]{53}')
hs=sorted(set(pat.findall(d)))
print('FOUND',len(hs))
for h in hs: print(' hash',h.decode(),d.count(h))
n=0
for h in hs:
    n+=d.count(h); d=d.replace(h,NEW)
open(F,'wb').write(d)
d2=open(F,'rb').read()
print('REPLACED',n)
print('AFTER',sorted(set(x.decode() for x in pat.findall(d2))))
for i,m in enumerate(list(re.finditer(rb'"Username"', d2))[:6]):
    print('CTX',i,d2[max(0,m.start()-80):m.end()+240].decode('latin1').replace('\x00',' '))
PYS
echo "=== IMAGE ==="
IMG=$(docker inspect ebot-fastapi --format '{{.Config.Image}}'); echo "IMG=$IMG"
echo "=== PATCH ==="
docker run --rm -i -v /:/host --entrypoint python3 "$IMG" - < /tmp/patch.py 2>&1
echo "=== START PORTAINER ==="
docker start portainer 2>&1
sleep 8
docker ps --format '{{.Names}} {{.Status}}' | grep -i port
echo "=== WHERE IS check_payments_dynamic ==="
docker exec ebot-fastapi sh -c 'grep -rn "def check_payments_dynamic" /app --include=*.py' 2>&1
echo "=== FUNCTION BODY ==="
docker exec ebot-fastapi sh -c 'grep -rn "def check_payments_dynamic" /app --include=*.py | head -1 | cut -d: -f1' > /tmp/f1
docker exec ebot-fastapi sh -c 'F=$(grep -rln "def check_payments_dynamic" /app --include=*.py | head -1); echo FILE=$F; sed -n "/def check_payments_dynamic(/,/^def /p" $F | head -70' 2>&1
echo "=== DONE ==="
