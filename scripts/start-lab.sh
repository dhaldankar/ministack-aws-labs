#!/usr/bin/env bash
set -euo pipefail

for file in main.tf check.sh; do
    if [[ ! -e /lab/$file ]]; then
        cp -p "/opt/exercise/$file" "/lab/$file"
    fi
done

exec python3 -m http.server 4000 --bind 0.0.0.0 --directory /opt/lab-site/dist
