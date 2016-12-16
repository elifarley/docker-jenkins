#!/bin/sh

 wget -qO- https://get.docker.com/ | sh

gpasswd -a admin docker

apt-get install mercurial

#---

mkdir -p ~admin/.ssh ~admin/bin

cat <<-EOF > ~admin/.hgrc
[ui]
username = BKP Robot <bkp@company.com>
ssh = ssh -i ~/.ssh/bkprobot@bitbucket.pem
EOF

curl -fsSL -o ~admin/bin/hgbkp-jenkins.sh \
https://gist.githubusercontent.com/elifarley/2d1842d9579063e2f3b3fce0516e62ec/raw/09801161d74a919bafb1b87891359ef3d6ede6fe/hgbkp-jenkins.sh

cat <<-EOF > ~admin/bin/app-bkp.sh
#!/bin/bash

time ~admin/bin/hgbkp-jenkins.sh ~admin/jenkins-home ssh://hg@bitbucket.org/user/company.jenkins main

EOF

chmod +x ~admin/bin/*

aws s3 cp s3://company.jenkins/mnt-ssh-config/known_hosts ~admin/.ssh/
aws s3 cp s3://company.jenkins.secrets/bkprobot@bitbucket.pem ~admin/.ssh/

chmod 0700 ~admin/.ssh
chmod 0400 ~admin/.ssh/*
chmod 0644 ~admin/.ssh/authorized_keys ~admin/.ssh/known_hosts
chown -R admin:admin ~admin/.ssh

sudo -u admin ~admin/bin/app-bkp.sh

echo "*/5 * * * *   ~admin/bin/app-bkp.sh" | crontab - -u admin

ln -s ~admin/jenkins-home/custom-config/bin/docker-jenkins.sh ~admin/bin/app.sh

exec sudo -u admin ~admin/bin/app.sh
