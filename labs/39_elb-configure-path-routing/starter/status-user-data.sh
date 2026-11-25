#!/usr/bin/env bash
set -euo pipefail
install -d -m 0755 /srv/lab-http
printf '%s\n' 'status backend' > /srv/lab-http/index.html
printf '%s\n' 'healthy' > /srv/lab-http/health
cp /srv/lab-http/index.html /srv/lab-http/status
cat > /etc/systemd/system/lab-http.service <<'UNIT'
[Unit]
Description=Lab HTTP server
After=network-online.target

[Service]
DynamicUser=yes
WorkingDirectory=/srv/lab-http
ExecStart=/usr/bin/python3 -m http.server 8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now lab-http.service
