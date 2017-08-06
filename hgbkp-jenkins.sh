#!/bin/sh

# Copies certain kinds of known files and directories from a given Jenkins master directory
# into a Mercurial repo (removing any old ones), adds, commits, and pushes them.
### Example ###
# ./hgbkp-jenkins.sh /path/to/jenkins-home ssh://hg@bitbucket.org/elifarley/my-jenkins main

test $# -eq 3 || {
  echo usage: "$0" jenkins_home hg_url local_store
  exit 1
}

dir_empty() { find -H "$1" -maxdepth 0 -empty | read v ;}

set -x

JENKINS_HOME=$1; shift
HG_URL=$1; shift
HG_REPOS_NAME="$(basename "$HG_URL")"
LOCAL_STORE="${1:-main}"

test "$LOCAL_STORE" = "$(basename "$LOCAL_STORE")" && LOCAL_STORE=/var/tmp/jenkins-bkp/"$LOCAL_STORE"

test -d "$(dirname "$LOCAL_STORE")/$HG_REPOS_NAME"/.hg || {
  echo "Cloning repository '$HG_URL' to '$(dirname "$LOCAL_STORE")/$HG_REPOS_NAME'..."
  hg clone "$HG_URL" "$(dirname "$LOCAL_STORE")/$HG_REPOS_NAME" || exit
}

mkdir -p "$(dirname "$LOCAL_STORE")/$HG_REPOS_NAME/$(basename "$LOCAL_STORE")" || exit

test -d "$JENKINS_HOME" && ! dir_empty "$JENKINS_HOME" || {
  echo "'$JENKINS_HOME' is empty. Restoring backup..."
  hg -v --cwd "$(dirname "$LOCAL_STORE")/$HG_REPOS_NAME" pull -u
  mkdir -p "$JENKINS_HOME" && \
  rsync -ahv "$(dirname "$LOCAL_STORE")/$HG_REPOS_NAME/$(basename "$LOCAL_STORE")"/ "$JENKINS_HOME" || exit
}

#    --exclude="config-history" \

rsync -ahv --delete \
    --exclude=".*.swp" \
    --exclude="**/.*.swp" \
    --exclude="workspace" \
    --exclude="war" \
    --exclude="plugins/*.bak" \
    --exclude="jobs/**/builds/*/archive" \
    --exclude="jobs/**/builds/*/workspace-files/*.tmp" \
    --exclude="jobs/**/modules/*/builds/*/log" \
    --exclude="jobs/**/modules/*/builds/*/archive" \
    --exclude="jobs/**/branches/*/builds/*/log" \
    --exclude="jobs/**/branches/*/builds/*/archive" \
    --exclude="jobs/**/workspace" \
    --exclude="jobs/**/scm-polling.log" \
    --exclude="logs" \
    --exclude=".cache" \
    --exclude=".ssh" \
    --exclude=".hudson" \
    --exclude=".java" \
    --exclude=".ivy2" \
    --exclude=".m2" \
    --exclude="lost+found" \
    --exclude="copy_reference_file.log" \
    --exclude="ThinBackup Worker Thread.log" \
    --exclude="Connection Activity monitoring to slaves.log" \
    --include="*.xml" \
    --include="*.key" \
    --include="*.key.enc" \
    --include="*.hpi" \
    --include="*.jpi" \
    --include="*.log" \
    --include="jenkins***" \
    --include=".owner" \
    --include="*pinned" \
    --include="*disabled" \
    --include="custom-config/***" \
    --include="secrets/***" \
    --include="users/***" \
    --include="userContent/***" \
    --include="fingerprints/***" \
    --include="init.groovy.d/***" \
    --include="scriptler/***" \
    --include="nodes/***" \
    --include="labels/***" \
    --include="shelvedProjects/***" \
    --include="config-history/***" \
    --include="updates/***" \
    --include="plugins/" \
    --include="plugins/*.?pi" \
    --include="plugins/*.pinned" \
    --include="workflow-libs/***" \
    --include="jobs/***" \
    --exclude="*" \
    --prune-empty-dirs "$JENKINS_HOME"/ "$(dirname "$LOCAL_STORE")/$HG_REPOS_NAME/$(basename "$LOCAL_STORE")" \
|| exit

hg -v --cwd "$(dirname "$LOCAL_STORE")/$HG_REPOS_NAME" addremove -s 50 . || exit

hg -v --cwd "$(dirname "$LOCAL_STORE")/$HG_REPOS_NAME" ci -u "$(id -nu)" -m "Jenkins '$(basename "$LOCAL_STORE")' [$(hostname -s) @ $(date -Is)]" && \
hg -v --cwd "$(dirname "$LOCAL_STORE")/$HG_REPOS_NAME" push

exit 0
