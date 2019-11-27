FROM alpine:latest
MAINTAINER Jesse Quinn <me@jessequinn.info>

RUN apk add --no-cache ca-certificates bash openssh-client rsync
COPY drone.sh /usr/local/

ENTRYPOINT ["/usr/local/drone.sh"]
