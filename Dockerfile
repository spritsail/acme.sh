FROM spritsail/alpine:3.17

ARG VERSION=3.0.5

LABEL maintainer="Spritsail <acme.sh@spritsail.io>" \
      org.label-schema.vendor="Spritsail" \
      org.label-schema.name="acme.sh" \
      org.label-schema.url="https://github.com/acmesh-official/acme.sh" \
      org.label-schema.vcs-url="https://github.com/spritsail/acme.sh" \
      org.label-schema.description="A pure Unix shell script implementing ACME client protocol" \
      org.label-schema.version=${VERSION} \
      io.spritsail.version.acme-sh=${VERSION}

ENV LE_WORKING_DIR=/acme.sh \
    _SCRIPT_HOME=/opt/acme.sh

WORKDIR $_SCRIPT_HOME

RUN apk --no-cache add -f \
      openssl \
      coreutils \
      bind-tools \
      curl \
      socat \
    && \
    curl -sSL https://github.com/Neilpang/acme.sh/archive/${VERSION}.tar.gz | tar xz --strip-components=1 && \
    chmod 755 ./acme.sh && \
    rm -rf .github Dockerfile README.md && \
    ln -sfv /opt/acme.sh/acme.sh /usr/local/bin

VOLUME /acme.sh
WORKDIR /acme.sh

SHELL ["/bin/sh", "-c"]

ENTRYPOINT \
    set -- "$0" "$@"; \
    if [ "$1" = "daemon" ]; then \
        # insert a crontab entry to run every hour, starting an hour from now
        echo "$(( $(date +%-M -d 'now') + 1 )) 0 * * * acme.sh --cron" | tee /dev/stderr | crontab -; \
        exec /sbin/tini -- crond -f -d6; \
    else \
        exec -- acme.sh "$@"; \
    fi

CMD ["--help"]
