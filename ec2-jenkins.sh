#!/bin/sh

#wget -qO- https://get.docker.com/ | sh

#gpasswd -a admin docker

#apt-get install mercurial

#---

set -x

_USER="${_USER:-admin}"
_COMPANY="${_COMPANY:-company}"

_HOME="$(getent passwd "$_USER" | cut -d: -f 6)"

mkdir -p "$_HOME"/.ssh "$_HOME"/bin

cat <<-EOF >> "$_HOME"/.hgrc || exit
[ui]
username = ${_COMPANY} Robot <${_COMPANY}robot@company.com>
EOF

cat <<-EOF >> "$_HOME"/.ssh/config || exit
Host bitbucket.org
  IdentityFile ~/.ssh/${_COMPANY}robot@bitbucket.pem
  IdentitiesOnly yes
  User git
EOF

curl -fsSL -o "$_HOME"/bin/hgbkp-jenkins.sh \
https://gist.githubusercontent.com/elifarley/2d1842d9579063e2f3b3fce0516e62ec/raw/b61a23a5353a0ce504300a0f3285b0f4603028e2/hgbkp-jenkins.sh

cat <<-EOF > "$_HOME"/bin/app-bkp.sh || exit
#!/bin/bash

time "$_HOME"/bin/hgbkp-jenkins.sh "$_HOME"/jenkins-home ssh://hg@bitbucket.org/elifarley/${_COMPANY}.jenkins main

EOF

chmod +x "$_HOME"/bin/* || exit

aws s3 --quiet cp s3://${_COMPANY}.jenkins/mnt-ssh-config/known_hosts /dev/stdout | cat >> "$_HOME"/.ssh/known_hosts && \
aws s3 cp s3://${_COMPANY}.jenkins.secrets/${_COMPANY}robot@bitbucket.pem "$_HOME"/.ssh/ || exit

chmod 0700 "$_HOME"/.ssh && \
chmod 0400 "$_HOME"/.ssh/* && \
chmod 0644 "$_HOME"/.ssh/known_hosts && \
chown -R "$_USER":"$_USER" "$_HOME"/.ssh || exit

sudo -u "$_USER" "$_HOME"/bin/app-bkp.sh || exit

echo "*/5 * * * *   '$_HOME'/bin/app-bkp.sh" | crontab - -u "$_USER" || exit

ln -s "$_HOME"/jenkins-home/custom-config/bin/docker-jenkins.sh "$_HOME"/bin/app.sh || exit

exec sudo -u "$_USER" "$_HOME"/bin/app.sh
