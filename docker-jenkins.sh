#!/bin/sh
CMD_BASE="$(readlink -f $0)" || CMD_BASE="$0"; CMD_BASE="$(dirname $CMD_BASE)"

IMAGE="elifarley/docker-jenkins-uidfv:2-latest"

set -x
docker pull "$IMAGE"

#--log-opt awslogs-region=sa-east-1 \
# JENKINS_ARGS="--prefix=/jenkins"

exec docker run --name jenkins \
--log-driver=awslogs \
--log-opt awslogs-group=/jenkins/master \
--log-opt awslogs-stream=$(hostname) \
--add-host artifactory:"$(getent hosts artifactory.company.com | cut -d' ' -f1)" \
-d --restart=always \
-p 8080:8080 -p 50000:50000 \
-v "$CMD_BASE"/../..:/var/jenkins_home \
-v "$CMD_BASE"/../mnt-ssh-config/certs:/mnt-ssh-config/certs:ro \
"$IMAGE" "$@"
