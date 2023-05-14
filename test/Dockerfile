ARG ENGINE_VERSION=5.6.0
FROM registry.gitlab.com/minetest/minetest/server:${ENGINE_VERSION}

USER root
RUN apk add git &&\
    mkdir -p /root/.minetest/worlds/world/worldmods/ &&\
    cd /root/.minetest/worlds/world/worldmods &&\
    git clone https://github.com/BuckarooBanzay/mtt &&\
    git clone https://github.com/minetest-mods/digilines &&\
    git clone https://github.com/minetest-mirrors/farming

ENTRYPOINT minetestserver --config /minetest.conf