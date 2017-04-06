#!/bin/sh
set -x
docker run --name zookeeper \
-d --restart=always -p 2181:2181 \
-v "/var/tmp/zookeeper:/var/tmp/zookeeper" \
jplock/zookeeper:3.4.8
