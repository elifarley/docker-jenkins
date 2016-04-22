FROM jenkins:alpine
MAINTAINER Elifarley Cruz <elifarley@gmail.com>

# See https://github.com/bdruemen/jenkins-docker-uid-from-volume/blob/master/Dockerfile
# Modify the UID of the jenkins user to automatically match the mounted volume.
# Use it just like the original: https://hub.docker.com/_/jenkins/

USER root

# Grab gosu for easy step-down from root.
ENV GOSU_SHA 18cced029ed8f0bf80adaa6272bf1650ab68f7aa
RUN curl -fsSL https://github.com/tianon/gosu/releases/download/1.5/gosu-amd64 -o /bin/gosu && chmod 755 /bin/gosu && \
  echo "$GOSU_SHA  /bin/gosu" | sha1sum -wc -

ENV TZ ${TZ:-Brazil/East}

RUN echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
  apk --update add --no-cache shadow tzdata && \
  echo "TZ set to '$TZ'" && cp -a /usr/share/zoneinfo/"$TZ" /etc/localtime && apk del tzdata && \
  rm -rf /var/cache/apk/*

ENTRYPOINT usermod -u $(stat -c "%u" /var/jenkins_home) jenkins && \
        exec /bin/tini -- gosu jenkins /usr/local/bin/jenkins.sh
