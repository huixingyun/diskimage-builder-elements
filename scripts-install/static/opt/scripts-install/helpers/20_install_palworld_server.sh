#!/bin/bash

# https://tech.palworldgame.com/dedicated-server-guide#linux
# https://github.com/thijsvanloef/palworld-server-docker

PALWORLD_DATA_DIR=${PALWORLD_DATA_DIR:-"/root/data/palworld"}
PALWORLD_ADMIN_PASSWORD=${PALWORLD_ADMIN_PASSWORD:-"secret-admin-password"}
PALWORLD_SERVER_NAME=${PALWORLD_SERVER_NAME:-"My Palworld Server"}
PALWORLD_PORT=${PALWORLD_PORT:-"8211"}
PALWORLD_PUBLIC_PORT=${PALWORLD_PUBLIC_PORT:-""}
PALWORLD_SERVER_PASSWORD=${PALWORLD_SERVER_PASSWORD:-"secret-server-password"}
PALWORLD_PLAYER=${PALWORLD_PLAYER:-"16"}

setup_palworld_docker_compose() {
    if [ -f ${PALWORLD_DATA_DIR}/docker-compose.yml ]; then
        echo "docker-compose.yml already exists"
        return
    fi

    mkdir -p ${PALWORLD_DATA_DIR}
    cat <<EOF > ${PALWORLD_DATA_DIR}/docker-compose.yml
services:
   palworld:
      image: thijsvanloef/palworld-server-docker:latest
      restart: unless-stopped
      container_name: palworld-server
      ports:
        - 8211:8211/udp
        - 27015:27015/udp
      environment:
         - PUID=1000
         - PGID=1000
         - PORT=8211
         - TZ=Asia/Shanghai
         - PLAYERS=${PALWORLD_PLAYER}
         - MULTITHREADING=true
         - RCON_ENABLED=true
         - RCON_PORT=25575
         - ADMIN_PASSWORD="${PALWORLD_ADMIN_PASSWORD}"
         - SERVER_PASSWORD="${PALWORLD_SERVER_PASSWORD}"
         - COMMUNITY=true
         - SERVER_NAME="${PALWORLD_SERVER_NAME}"
         - PUBLIC_PORT=${PALWORLD_PUBLIC_PORT}
         - UPDATE_ON_BOOT=true
         # Special Server Settings
         - DAYTIME_SPEEDRATE=0.7
         - NIGHTTIME_SPEEDRATE=1.2
         - EXP_RATE=1.5
         - PAL_CAPTURE_RATE=1.5
         - COLLECTION_DROP_RATE=3
         - ENEMY_DROP_ITEM_RATE=2
         - DEATH_PENALTY=None
         - PAL_EGG_DEFAULT_HATCHING_TIME=2
         - WORK_SPEED_RATE=2
      volumes:
         - ./:/palworld/
EOF
}

start_palworld_server() {
    install_docker
    setup_palworld_docker_compose
    docker compose -f ${PALWORLD_DATA_DIR}/docker-compose.yml up -d
}
