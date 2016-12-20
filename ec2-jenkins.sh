#!/bin/sh

 wget -qO- https://get.docker.com/ | sh

gpasswd -a admin docker

apt-get install mercurial

#---

mkdir -p ~admin/.ssh ~admin/bin

cat <<-EOF >> ~admin/.hgrc || exit
[ui]
username = BKP Robot <bkp@company.com>
EOF

cat <<-EOF >> ~/.ssh/config || exit
Host bitbucket.org
  IdentityFile ~/.ssh/bkprobot@bitbucket.pem
  IdentitiesOnly yes
  User git
EOF

curl -fsSL -o ~admin/bin/hgbkp-jenkins.sh \
https://gist.githubusercontent.com/elifarley/2d1842d9579063e2f3b3fce0516e62ec/raw/63623be878ffbb6f77c490c93a567b403f57d185/hgbkp-jenkins.sh

cat <<-EOF > ~admin/bin/app-bkp.sh || exit
#!/bin/bash

time ~admin/bin/hgbkp-jenkins.sh ~admin/jenkins-home ssh://hg@bitbucket.org/user/company.jenkins main

EOF

chmod +x ~admin/bin/* || exit

aws s3 --quiet cp s3://company.jenkins/mnt-ssh-config/known_hosts /dev/stdout | cat >> ~admin/.ssh/known_hosts && \
aws s3 cp s3://company.jenkins.secrets/bkprobot@bitbucket.pem ~admin/.ssh/ || exit

chmod 0700 ~admin/.ssh && \
chmod 0400 ~admin/.ssh/* && \
chmod 0644 ~admin/.ssh/authorized_keys ~admin/.ssh/known_hosts && \
chown -R admin:admin ~admin/.ssh || exit

sudo -u admin ~admin/bin/app-bkp.sh || exit

echo "*/5 * * * *   ~admin/bin/app-bkp.sh" | crontab - -u admin || exit

ln -s ~admin/jenkins-home/custom-config/bin/docker-jenkins.sh ~admin/bin/app.sh || exit

exec sudo -u admin ~admin/bin/app.sh
