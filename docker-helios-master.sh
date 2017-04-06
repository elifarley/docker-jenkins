#!/bin/sh
set -x

docker run --name helios-master \
-d --restart=always -p 5801:5801 \
--volume "/var/tmp/zookeeper:/tmp/zookeeper" \
fguerco/helios-master \
--zk $(hostname -I | cut -d' ' -f1):2181
