#!/usr/bin/env bash
set -euo pipefail

lab welcome

exec python3 -m http.server 4000 --bind 0.0.0.0 --directory /opt/lab-site/dist
