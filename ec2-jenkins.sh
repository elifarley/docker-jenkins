#!/bin/sh

 wget -qO- https://get.docker.com/ | sh

gpasswd -a admin docker

apt-get install mercurial

#---

_USER="${_USER:-admin}"
_COMPANY="${_COMPANY:-company}"

mkdir -p ~"$_USER"/.ssh ~"$_USER"/bin

cat <<-EOF >> ~"$_USER"/.hgrc || exit
[ui]
username = ${_COMPANY} Robot <${_COMPANY}robot@company.com>
EOF

cat <<-EOF >> ~/.ssh/config || exit
Host bitbucket.org
  IdentityFile ~/.ssh/${_COMPANY}robot@bitbucket.pem
  IdentitiesOnly yes
  User git
EOF

curl -fsSL -o ~"$_USER"/bin/hgbkp-jenkins.sh \
https://gist.githubusercontent.com/elifarley/2d1842d9579063e2f3b3fce0516e62ec/raw/63623be878ffbb6f77c490c93a567b403f57d185/hgbkp-jenkins.sh

cat <<-EOF > ~"$_USER"/bin/app-bkp.sh || exit
#!/bin/bash

time ~"$_USER"/bin/hgbkp-jenkins.sh ~"$_USER"/jenkins-home ssh://hg@bitbucket.org/user/company.jenkins main

EOF

chmod +x ~"$_USER"/bin/* || exit

aws s3 --quiet cp s3://company.jenkins/mnt-ssh-config/known_hosts /dev/stdout | cat >> ~"$_USER"/.ssh/known_hosts && \
aws s3 cp s3://company.jenkins.secrets/${_COMPANY}robot@bitbucket.pem ~"$_USER"/.ssh/ || exit

chmod 0700 ~"$_USER"/.ssh && \
chmod 0400 ~"$_USER"/.ssh/* && \
chmod 0644 ~"$_USER"/.ssh/authorized_keys ~"$_USER"/.ssh/known_hosts && \
chown -R "$_USER":"$_USER" ~"$_USER"/.ssh || exit

sudo -u "$_USER" ~"$_USER"/bin/app-bkp.sh || exit

echo "*/5 * * * *   ~'$_USER'/bin/app-bkp.sh" | crontab - -u "$_USER" || exit

ln -s ~"$_USER"/jenkins-home/custom-config/bin/docker-jenkins.sh ~"$_USER"/bin/app.sh || exit

exec sudo -u "$_USER" ~"$_USER"/bin/app.sh
