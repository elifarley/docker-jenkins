#!/bin/sh

_USER=admin

wget -qO- https://get.docker.com/ | sh

gpasswd -a "$_USER" docker

apt-get install mercurial time bzip2

xinstall add tar
xinstall cleanup

#--- Jenkins Amazon EC2 Cloud Plugin - Init Script:

set -x

id

test -L /app -o -e /app || {
  sudo ln -s ~/app /app || exit
}

mkdir -p ~/app ~/.ssh || exit

cat <<-EOF >> ~/.hgrc || exit
[ui]
username = Jenkins Slave <dev_m4urobot@m4u.com.br>
EOF

cat <<-EOF >> ~/.ssh/config || exit
Host bitbucket.org
  IdentityFile ~/.ssh/m4urobot@bitbucket.pem
  IdentitiesOnly yes
  User git
EOF

aws s3 --quiet cp s3://m4u.jenkins/mnt-ssh-config/known_hosts /dev/stdout | cat >> ~/.ssh/known_hosts && \
aws s3 cp s3://m4u.jenkins.secrets/m4urobot@bitbucket.pem ~/.ssh/ || exit

chmod 0700 ~/.ssh && \
chmod 0400 ~/.ssh/* &&
chmod u+w ~/.ssh/known_hosts || exit
for k in ~/.ssh/*.pub; do
  test -e "$k" && chmod a+r "$k"
done

# --

HG_URL='ssh://hg@bitbucket.org/elifarley/m4u.jenkins-slave.config'

if test -d ~/jenkins-slave.config/.hg; then
  hg --cwd ~/jenkins-slave.config pull && hg --cwd ~/jenkins-slave.config up -C
else
  echo "Cloning repository '$HG_URL' to '$HOME/jenkins-slave.config'..."
  hg clone "$HG_URL" ~/jenkins-slave.config || exit
fi

mkdir -p ~/.m2 ~/.gradle ~/.docker && ( cd ~/jenkins-slave.config && \
chmod go= mvn-settings.xml gradle.properties docker-config.json && \
cp -av mvn-settings.xml ~/.m2/settings.xml && \
cp -av gradle.properties ~/.gradle/gradle.properties && \
cp -av docker-config.json ~/.docker/config.json ) || exit

sudo JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/default-jvm}" /usr/local/bin/keytool-import-certs --force ~/jenkins-slave.config/mnt-ssh-config/certs
