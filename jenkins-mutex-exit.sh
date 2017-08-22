#!/bin/sh
test "$DEBUG" && set -x

url="$1"; shift
mpath="$1"

sleep 30

while true; do

  sleep 30

  test -L "$mpath"/lock || { echo "'$mpath/lock' no longer exists'"; exit ;}

  str="$(curl -fsSL $url)" || { echo "HTTP error for '$url'"; break ;}

  test "$(echo $str | jq .building)" = 'true' || break

done

mv "$mpath"/lock "$mpath"/lock.delete-me && rm -v "$mpath"/lock.delete-me
