#!/bin/sh

# Configuration
#--------------------------------------------------------------------

JNAME=my-jenkins-name
_COMPANY=company
_EMAIL='cd-robot@company.com'
BITBUCKET_ROOT='company'
BITBUCKET_PEM="${_COMPANY}robot@bitbucket.pem"


#--------------------------------------------------------------------

JNAME="$(echo $JNAME | tr '[:upper:]' '[:lower:]')"
_COMPANY="$(echo $_COMPANY | tr '[:upper:]' '[:lower:]')"

install_debian() {
  JUSER="${1:-admin}"
  wget -qO- https://get.docker.com/ | sh
  apt-get install mercurial
}

install_amazon() {
  JUSER="${1:-ec2-user}"
  yum update -y && \
  yum install -y mercurial docker && \
  service docker start
}

install_amazon || exit

gpasswd -a "$JUSER" docker || exit

get_home() {
  local result; result="$(getent passwd "$1")" || return
  echo $result | cut -d : -f 6
}

JHPARENT="$(get_home "$JUSER")"

mkdir -p "$JHPARENT"/.ssh "$JHPARENT"/bin || exit

cat <<-EOF >"$JHPARENT"/.hgrc || exit
[ui]
username = Jenkins Backup Robot <$_EMAIL>
ssh = ssh -i '$JHPARENT/.ssh/$BITBUCKET_PEM'
EOF

cat <<-EOF >>"$JHPARENT"/.ssh/config || exit
Host bitbucket.org
  IdentityFile '$JHPARENT/.ssh/$BITBUCKET_PEM'
  IdentitiesOnly yes
  User git

EOF

curl -fsSL -o "$JHPARENT"/bin/hgbkp-jenkins.sh \
https://gist.githubusercontent.com/elifarley/2d1842d9579063e2f3b3fce0516e62ec/raw/09801161d74a919bafb1b87891359ef3d6ede6fe/hgbkp-jenkins.sh \
|| exit

cat <<-EOF >"$JHPARENT"/bin/app-bkp.sh || exit
#!/bin/env bash
JNAME='$JNAME'
URL="ssh://hg@bitbucket.org/$BITBUCKET_ROOT/${_COMPANY}.jenkins.\$JNAME"
JHPARENT='$JHPARENT'

time "\$JHPARENT"/bin/hgbkp-jenkins.sh "\$JHPARENT"/jenkins-home "\$URL" main

EOF

chmod +x "$JHPARENT"/bin/* || exit

cat <<-EOF >>"$JHPARENT"/.ssh/known_hosts || exit
bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==
EOF

test -e "$JHPARENT/.ssh/$BITBUCKET_PEM" || {
  aws s3 cp s3://$_COMPANY.jenkins.secrets.$JNAME/$BITBUCKET_PEM "$JHPARENT"/.ssh/ || exit
}

chown -R "$JUSER":"$JUSER" "$JHPARENT"/.ssh && \
chmod 0700 "$JHPARENT"/.ssh && \
chmod 0400 "$JHPARENT"/.ssh/* || exit
chmod 0644 "$JHPARENT"/.ssh/known_hosts "$JHPARENT"/.ssh/authorized_keys
for k in "$JHPARENT"/.ssh/*.pub; do
  test -e "$k" && { chmod a+r "$k" || exit ;}
done
md5sum "$JHPARENT"/.ssh/*

sudo -u "$JUSER" "$JHPARENT"/bin/app-bkp.sh

echo "*/5 * * * *   '$JHPARENT'/bin/app-bkp.sh" | crontab - -u "$JUSER" || exit

ln -s "$JHPARENT"/jenkins-home/custom-config/bin/docker-jenkins.sh "$JHPARENT"/bin/app.sh || exit

exec sudo -u "$JUSER" "$JHPARENT"/bin/app.sh
