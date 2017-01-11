UPSTREAM_JOB_NAME="${1:-UPSTREAM_JOB_NAME}"
UPSTREAM_BUILD_NUMBER="${2:-UPSTREAM_BUILD_NUMBER}"

STREAM_NAME="$UPSTREAM_JOB_NAME/$UPSTREAM_BUILD_NUMBER"

strcontains() { test -z "${1##*$2*}" ; }

strcontains "$UPSTREAM_JOB_NAME" '/' && \
UPSTREAM_JOB_NAME="$(dirname "$UPSTREAM_JOB_NAME")/job/$(basename "$UPSTREAM_JOB_NAME")"

curl -fsSL "${JENKINS_URL}job/$UPSTREAM_JOB_NAME/$UPSTREAM_BUILD_NUMBER/timestamps/?time=HH:mm:ss&appendLog" | \
aws logs push \
--log-group-name /jenkins/jobs \
--log-stream-name "$STREAM_NAME" \
--datetime-format '%b %d %H:%M:%S' \
--time-zone LOCAL \
--encoding utf-8
