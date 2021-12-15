FROM node:14-slim
WORKDIR /hub

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y curl git jq

RUN curl -fsSL https://github.com/github/hub/raw/master/script/get | bash -s 2.14.1
ENV PATH="/hub/bin:${PATH}"

WORKDIR /action

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
