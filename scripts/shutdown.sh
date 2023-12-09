#!/usr/bin/env sh

bash scripts/linters.sh

echo '---- SHUTDOWN DOCKER ----'
docker-compose -f ./environment/docker-compose.yaml down --remove-orphans