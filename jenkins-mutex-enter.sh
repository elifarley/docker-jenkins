#!/bin/sh
CMD_BASE="$(readlink -f "$0")" || CMD_BASE="$0"; CMD_BASE="$(dirname "$CMD_BASE")"

mutex_enter() {
  local name="${1:-main}"
  local mpath="${MUTEX_BASE:-/tmp/.mutexes}/$name"
  mkdir -p "$mpath"; test -d "$mpath" || return
  while ! ln -s . "$mpath"/lock 2>/dev/null; do sleep 5; done
  mutex_on_enter "$mpath" nocron
}

mutex_on_enter() {
  # http://jenkins-lio-tms.m4u.orgecc.com:8083/job/store/job/master/2/api/json?tree=building
  # {"_class":"org.jenkinsci.plugins.workflow.job.WorkflowRun","building":false}
  local url="${BUILD_URL:?}/api/json?tree=building"
  echo $BUILD_URL | sed -re 's;api/json.+;;' > "$1"/url
  test "$2" = cron && {
    local cmd="'$CMD_BASE'/jenkins-mutex-cron-exit.sh"
    (crontab -l 2>/dev/null; echo '*/1 * * * *' "$cmd '$url' '$1'") | crontab -
    return
  }

  "$CMD_BASE"/jenkins-mutex-exit.sh "$url" "$1" &
}

test "$DEBUG" && set -x
mutex_enter "$@"
