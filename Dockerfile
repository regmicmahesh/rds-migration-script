FROM debian:stable-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install wget lsb-release postgresql-client -y

WORKDIR /app

COPY migration-script.sh .

CMD ["/bin/bash", "/app/migration-script.sh"]

