test "$DEBUG" && set -x

UPSTREAM_JOB_NAME="${1:-UPSTREAM_JOB_NAME}"
UPSTREAM_BUILD_NUMBER="${2:-UPSTREAM_BUILD_NUMBER}"

STREAM_NAME="$UPSTREAM_JOB_NAME/$UPSTREAM_BUILD_NUMBER"

strcontains() { test -z "${1##*$2*}" ; }

strcontains "$UPSTREAM_JOB_NAME" '/' && \
UPSTREAM_JOB_NAME="$(dirname "$UPSTREAM_JOB_NAME")/job/$(basename "$UPSTREAM_JOB_NAME")"

base_url="${JENKINS_URL}job/$UPSTREAM_JOB_NAME/$UPSTREAM_BUILD_NUMBER"
log_path='consoleText'; time_format=''
curl -fsSL "$base_url"/timestamps'?time=HH:mm:ss&endLine=1' | \
egrep -q '^([[:digit:]]{2}:){2}[[:digit:]]{2}$' && {
  log_path='timestamps?time=HH:mm:ss&elapsed=HH:mm:ss.S&appendLog'; time_format="--datetime-format %H:%M:%S"
}

curl -fsSL "$base_url"/"$log_path" | \
aws logs push \
--log-group-name /jenkins/jobs \
--log-stream-name "$STREAM_NAME" \
$time_format \
--time-zone LOCAL \
--encoding utf-8
