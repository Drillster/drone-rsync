FROM alpine:3.4
MAINTAINER Michael de Wit <michael@drillster.com>

RUN apk add --no-cache ca-certificates bash openssh-client rsync
COPY transfer.sh /usr/local/

ENTRYPOINT ["/usr/local/transfer.sh"]
