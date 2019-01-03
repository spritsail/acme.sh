FROM alpine:3.8

ARG VERSION=master

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
    rm -rf .github .travis.yml Dockerfile README.md && \
    ln -sfv /opt/acme.sh/acme.sh /usr/local/bin

VOLUME /acme.sh
WORKDIR /acme.sh

ENTRYPOINT \
    set -- "$0" "$@"; \
    if [ "$1" = "daemon" ]; then \
        trap "echo stop && killall crond && exit 0" SIGTERM SIGINT; \
        # insert a crontab entry to run every hour, starting an hour from now
        echo "$(date +%-M) 0 * * * acme.sh --cron" | tee /dev/stderr | crontab -; \
        crond && while true; do sleep 1; done; \
    else \
        exec -- acme.sh "$@"; \
    fi

CMD ["--help"]
