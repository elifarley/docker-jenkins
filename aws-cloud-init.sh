#!/bin/sh

 wget -qO- https://get.docker.com/ | sh

gpasswd -a admin docker

apt-get install mercurial

IMAGE="elifarley/docker-jenkins-uidfv:2-latest"

sudo -u admin docker pull "$IMAGE"

exec sudo -u admin docker run --name jenkins \
-d --restart=always \
-p 8080:8080 -p 50000:50000 \
-v /home/admin/jenkins-home:/var/jenkins_home \
-v /home/admin/certs:/mnt-ssh-config/certs:ro \
"$IMAGE"
