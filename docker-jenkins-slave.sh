#!/bin/sh
CMD_BASE="$(readlink -f "$0")" || CMD_BASE="$0"; CMD_BASE="$(dirname "$CMD_BASE")"

set -x
IMAGE="elifarley/docker-jenkins-slaves:openjdk-8-sshd-devel"
IMAGE="elifarley/docker-dev-env:debian-openjdk-8-sshd-compiler"
docker pull "$IMAGE"

curl -fsL --connect-timeout 1 http://169.254.169.254/latest/meta-data/local-ipv4 >/dev/null && {
  log_config="
  --log-driver=awslogs
  --log-opt awslogs-group=/jenkins/slave
  --log-opt awslogs-stream='$(hostname)/$(basename "$IMAGE")@$(date -Is)'
  "
  cp -av ~/.ssh/*.p?? "$CMD_BASE"/../mnt-ssh-config/
}

DOCKER_LIBS="$(ldd $(which docker) | grep libdevmapper | cut -d' ' -f3)"
MOUNT_DOCKER="\
-v /var/run/docker.sock:/var/run/docker.sock \
-v $DOCKER_LIBS:$DOCKER_LIBS:ro \
-v $(which docker):$(which docker):ro
"

exec docker run --name jenkins-slave-devel \
-p 2200:2200 -p 9910:9910 -p 9911:9911 \
--dns=10.11.64.21 --dns=10.11.64.22 --dns-search=m4ucorp.dmc \
-v /var/tmp/jenkins-slave:/data \
-v "$CMD_BASE"/../mnt-ssh-config/:/mnt-ssh-config:ro \
-v "$CMD_BASE"/../mvn-settings.xml:/app/.m2/settings.xml:ro \
-v "$CMD_BASE"/../gradle.properties:/app/.gradle/gradle.properties:ro \
$log_config \
$MOUNT_DOCKER \
-e JAVA_OPTS="\
-Dcom.sun.management.jmxremote \
-Dcom.sun.management.jmxremote.ssl=false \
-Dcom.sun.management.jmxremote.authenticate=false \
-Dcom.sun.management.jmxremote.port=9910 \
-Dcom.sun.management.jmxremote.rmi.port=9911 \
-Djava.rmi.server.hostname=$(curl -fsL --connect-timeout 1 http://169.254.169.254/latest/meta-data/local-ipv4 || hostname)" \
-d --restart=always \
"$IMAGE" "$@"
