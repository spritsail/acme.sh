FROM spritsail/alpine:3.21

ARG VERSION=3.0.7

LABEL org.opencontainers.image.authors="Spritsail <acme.sh@spritsail.io>" \
      org.opencontainers.image.title="acme.sh" \
      org.opencontainers.image.url="https://github.com/acmesh-official/acme.sh" \
      org.opencontainers.image.source="https://github.com/spritsail/acme.sh" \
      org.opencontainers.image.description="A pure Unix shell script implementing ACME client protocol" \
      org.opencontainers.image.version=${VERSION} \
      io.spritsail.version.acme-sh=${VERSION}

WORKDIR /var/lib/acmesh

RUN apk --no-cache add -f \
        bind-tools \
        coreutils \
        curl \
        docker-cli \
        openssl \
        socat \
    && \
    curl -sSL https://github.com/acmesh-official/acme.sh/archive/${VERSION}.tar.gz | tar xz --strip-components=1 && \
    chmod 755 acme.sh && \
    rm -rf .github Dockerfile README.md && \
    ln -sfv $PWD/acme.sh /usr/bin/acme.sh && \
    ln -sfv $PWD/acme.sh /usr/bin/acme

ENV CERT_HOME=/acme.sh
VOLUME ${CERT_HOME}
WORKDIR ${CERT_HOME}

SHELL ["/bin/sh", "-c"]

ENTRYPOINT \
    set -- "$0" "$@"; \
    if [ "$1" = "daemon" ]; then \
        # insert a crontab entry to run every hour, starting an hour from now
        echo "$(( $(date +%-M -d 'now') + 1 )) 0 * * * acme.sh --cron" | tee /dev/stderr | crontab -; \
        # Run a renew immediately on container start
        acme.sh --cron; \
        exec /sbin/tini -- crond -f -d6; \
    else \
        exec -- acme.sh "$@"; \
    fi

CMD ["--help"]
