#!/bin/sh

_USER=admin

wget -qO- https://get.docker.com/ | sh

gpasswd -a "$_USER" docker

apt-get install mercurial

#---

_USER=admin

ln -s ~"$_USER" /app

mkdir -p /app/.ssh /app/bin

cat <<-EOF > /app/.hgrc
[ui]
username = Slave Robot <slave@company.com>
ssh = ssh -i ~/.ssh/slave-robot@bitbucket.pem
EOF

cat <<-EOF > /app/bin/app.sh
#!/bin/bash
set -x
IMAGE="elifarley/docker-jenkins-slaves:alpine-jdk-8"
docker pull "\$IMAGE"

test -f ~/.hgrc && hgrc="-v \$HOME/.hgrc:/app/.hgrc:ro" || unset hgrc
test -f ~/.gitconfig && gitconfig="-v \$HOME/.gitconfig:/app/.gitconfig:ro" || unset gitconfig
test -d ~/.m2 && m2dir="-v \$HOME/.m2:/app/.m2" || unset m2dir

docker rm -f jenkins-slave-alpine

exec docker run --name jenkins-slave.alpine-jdk-8 \
--add-host artifactory.m4ucorp.dmc:"\$(getent hosts artifactory.m4ucorp.dmc | cut -d' ' -f1)" \
--add-host codeload.github.com:192.30.253.121 \
-p 2200:2200 \
-d --restart=always \
\$hgrc \$gitconfig \$m2dir \
-v ~/data/known_hosts:/mnt-ssh-config/known_hosts:ro \
-v ~/data/id_rsa.pub:/mnt-ssh-config/authorized_keys:ro \
-v ~/data/bitbucket-private-key:/mnt-ssh-config/id_rsa:ro \
-v ~/data/thundercats-private-key:/mnt-ssh-config/id_rsa-thundercats:ro \
-v ~/data/gradle.properties:/app/.gradle/gradle.properties:ro \
-v ~/data/certs:/mnt-ssh-config/certs:ro \
-v ~/jenkins-slave:/data \
"\$IMAGE" "\$@"

EOF

chmod +x /app/bin/*

aws s3 cp s3://company.jenkins/mnt-ssh-config/known_hosts /app/.ssh/
aws s3 cp s3://company.jenkins.secrets/bkprobot@bitbucket.pem /app/.ssh/

chmod 0700 /app/.ssh
chmod 0400 /app/.ssh/*
chmod 0644 /app/.ssh/authorized_keys /app/.ssh/known_hosts
chown -R "$_USER":"$_USER" /app/.ssh

exec sudo -u "$_USER" /app/bin/app.sh
