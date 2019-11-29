FROM alpine:3.8
MAINTAINER Michael de Wit <michael@drillster.com>

RUN apk add --no-cache ca-certificates bash openssh-client rsync
COPY upload.sh /usr/local/

ENTRYPOINT ["/usr/local/upload.sh"]
