#!/bin/sh

_USER=admin

wget -qO- https://get.docker.com/ | sh

gpasswd -a "$_USER" docker

apt-get install mercurial

#--- Jenkins Amazon EC2 Cloud Plugin - Init Script:

id

mkdir ~/.ssh ~/.gradle ~/.docker || exit

cat <<-EOF >> ~/.hgrc || exit
[ui]
username = Jenkins Slave <dev_m4urobot@m4u.com.br>
ssh = ssh -i ~/.ssh/m4urobot@bitbucket.pem
EOF

aws s3 --quiet cp s3://m4u.jenkins/mnt-ssh-config/known_hosts /dev/stdout | cat >> ~/.ssh/known_hosts && \
aws s3 cp s3://m4u.jenkins.secrets/m4urobot@bitbucket.pem ~/.ssh/ || exit

chmod 0700 ~/.ssh && \
chmod 0400 ~/.ssh/* && \
chmod 0644 ~/.ssh/authorized_keys ~/.ssh/known_hosts || exit

hg clone 'ssh://hg@bitbucket.org/elifarley/m4u.jenkins-slave.config' ~/jenkins-slave.config || exit

cp -av ~/jenkins-slave.config/docker-config.json ~/.docker/config.json && \
cp -av ~/jenkins-slave.config/gradle.properties ~/.gradle/gradle.properties || exit

sudo JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/default-jvm}" /usr/local/bin/keytool-import-certs --force ~/jenkins-slave.config/mnt-ssh-config/certs
