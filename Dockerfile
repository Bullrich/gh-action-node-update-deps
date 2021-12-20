FROM alpine/git
RUN set -ex

RUN apk add --update --no-cache bash wget openssh libc6-compat nodejs npm yarn curl jq

WORKDIR /action

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
