FROM alpine:3.5
MAINTAINER cma@nine.ch

RUN apk add --no-cache --virtual .run-deps \
    ca-certificates curl \
    && update-ca-certificates

ENV DOCKER_GEN_VERSION 0.7.3

RUN curl -sL https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-alpine-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
    | tar -xz -C /usr/local/bin

RUN mkdir /app
WORKDIR /app
COPY . /app/

ENV DOCKER_HOST unix:///tmp/docker.sock
ENV RECEPTION_TLD docker
ENV UMASK 113

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["docker-gen","-config","docker-gen.in_docker.conf"]
