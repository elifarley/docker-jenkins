FROM jenkins:alpine
MAINTAINER Elifarley Cruz <elifarley@gmail.com>
ENV BASE_IMAGE=jenkins:alpine \
\
GOSU_VERSION='1.10' \
_USER=jenkins \
TZ=${TZ:-Brazil/East} \
TERM=xterm-256color \
MNT_DIR=/var/jenkins_home

ENV JAVA_TOOL_OPTIONS="-Duser.timezone=$TZ"

# See https://github.com/bdruemen/jenkins-docker-uid-from-volume/blob/master/Dockerfile
# Modify the UID of the jenkins user to automatically match the mounted volume.
# Use it just like the original: https://hub.docker.com/_/jenkins/

ENTRYPOINT ["/bin/tini", "--", "entrypoint"]
CMD ["/usr/local/bin/jenkins.sh"]

USER root
RUN curl -fsSL https://raw.githubusercontent.com/elifarley/cross-installer/master/install.sh | sh && \
  xinstall save-image-info && \
  xinstall add entrypoint && \
  xinstall add timezone && \
  xinstall add gosu "$GOSU_VERSION" && \
  xinstall cleanup
