FROM python

RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
        shfmt \
        shellcheck \
        bats \
    && rm --force --recursive /var/lib/apt/lists/*
