#!/bin/sh
echo "=== DOCKER PS (short) ==="
docker ps --format '{{.Names}}'
echo "=== ebot-fastapi tree ==="
docker exec ebot-fastapi sh -c 'ls -la / ; echo ---; ls -la /app 2>/dev/null; echo ---; find / -maxdepth 5 -name "*.py" 2>/dev/null | grep -viE "site-packages|dist-packages|/usr/lib" | head -80' 2>&1 | head -140
echo "=== ebot-fastapi crypto grep ==="
docker exec ebot-fastapi sh -c 'grep -rniE "encrypted_pk|encrypt|decrypt|fernet|AES|Cipher|private_key|privatekey" /app /srv /code /root /opt 2>/dev/null | grep -viE "site-packages|dist-packages" | head -120' 2>&1 | head -160
echo "=== ebot-telegram tree+grep ==="
docker exec ebot-telegram sh -c 'ls -la /app 2>/dev/null; find / -maxdepth 4 -name "*.py" 2>/dev/null | grep -viE "site-packages|dist-packages|/usr/lib" | head -40; grep -rniE "encrypted_pk|encrypt|decrypt|fernet|ENCRYPT-KEY|pay_here|payhere" /app /srv /code /root 2>/dev/null | grep -viE "site-packages|dist-packages" | head -80' 2>&1 | head -160
echo "=== DONE ==="
