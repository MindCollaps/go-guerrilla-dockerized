FROM golang AS builder
WORKDIR /source
RUN curl https://glide.sh/get | sh
RUN apt-get update && apt-get install -y git
RUN go get github.com/phires/go-guerrilla
RUN cd /go/src/github.com/phires/go-guerrilla && glide install && make guerrillad
RUN mkdir /app && cp /go/src/github.com/phires/go-guerrilla/guerrillad /app

# Use an official lightweight Alpine base image
FROM alpine AS SSL

# Install OpenSSL
RUN apk update && apk add openssl

# Create SSL files directory
RUN mkdir -p /ssl

WORKDIR /ssl

# Generate private key and certificate for weebskingdom.com
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /ssl/weebskingdom.com.key \
  -out /ssl/weebskingdom.com.crt \
  -subj "/C=DE/ST=State/L=City/O=Organization/OU=Unit/CN=mail.weebskingdom.com"

# Generate private key and certificate for neoin.space
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /ssl/neoin.space.key \
  -out /ssl/neoin.space.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=mail.neoin.space"

FROM alpine

RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2

WORKDIR /app

COPY --from=builder "/app" .

RUN mkdir /config

VOLUME /config

COPY --from=SSL /ssl/* .
COPY goguerrilla.conf.json /config/goguerrilla.conf.json

CMD ["/app/guerrillad", "serve", "-c", "/config/goguerrilla.conf.json"]