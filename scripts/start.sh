#!/usr/bin/env sh

echo '---- START DOCKER ----'
docker-compose -f ./environment/docker-compose.yaml down --remove-orphans -v
docker-compose -f ./environment/docker-compose.yaml build --no-cache
docker-compose -f ./environment/docker-compose.yaml up -d
sleep 5
# sleep 30
# ^ option for Zakhar....
python3 ./logic/simulate.py