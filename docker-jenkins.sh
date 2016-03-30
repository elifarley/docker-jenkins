#!/bin/bash
set -x
IMAGE="quay.io/elifarley/jenkins"
docker pull "$IMAGE"

exec docker run --name jenkins \
-d --restart=always \
-p 8080:8080 -p 50000:50000 \
-v ~/data/jenkins:/var/jenkins_home \
"$IMAGE" "$@"
