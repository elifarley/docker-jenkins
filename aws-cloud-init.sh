#!/bin/sh

 wget -qO- https://get.docker.com/ | sh

gpasswd -a admin docker

apt-get install mercurial

#---

mkdir -p ~admin/.ssh ~admin/certs ~admin/bin

cat <<-EOF > ~admin/.hgrc
[ui]
username = BKP Robot <bkp@company.com>
ssh = ssh -i ~/.ssh/bkprobot@bitbucket.pem
EOF

curl -fsSL -o ~admin/bin/hgbkp-jenkins.sh \
https://gist.githubusercontent.com/elifarley/2d1842d9579063e2f3b3fce0516e62ec/raw/55795df723dbf7b999733f4a6a7285ca86f38b5c/hgbkp-jenkins.sh

IMAGE="elifarley/docker-jenkins-uidfv:2-latest"

cat <<-EOF > ~admin/bin/app.sh
#!/bin/sh

IMAGE="$IMAGE"

exec docker run --name jenkins \
-d --restart=always \
-p 8080:8080 -p 50000:50000 \
-v /home/admin/jenkins-home:/var/jenkins_home \
-v /home/admin/certs:/mnt-ssh-config/certs:ro \
"\$IMAGE"

EOF

cat <<-EOF > ~admin/bin/app-bkp.sh
#!/bin/bash

time ~admin/bin/hgbkp-jenkins.sh ~admin/jenkins-home ssh://hg@bitbucket.org/user/company.jenkins main

EOF

chmod +x ~admin/bin/*

sudo -u admin docker pull "$IMAGE"

aws s3 cp s3://company.jenkins/certs/m4u-artifactory ~admin/certs/

aws s3 cp s3://company.jenkins/mnt-ssh-config/known_hosts ~admin/.ssh/

aws s3 cp s3://company.jenkins/mnt-ssh-config/authorized_keys - >> ~admin/.ssh/authorized_keys

aws s3 cp s3://company.jenkins.secrets/bkprobot@bitbucket.pem ~admin/.ssh/

chmod 0700 ~admin/.ssh
chmod 0400 ~admin/.ssh/*
chown -R admin ~admin/.ssh

sudo -u admin ~admin/bin/app-bkp.sh

echo "*/5 * * * *   ~admin/bin/app-bkp.sh" | crontab - -u admin

exec sudo -u admin ~admin/bin/app.sh
