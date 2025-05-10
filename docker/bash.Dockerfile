FROM node

RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
        shfmt \
        shellcheck \
        bats \
    && rm --force --recursive /var/lib/apt/lists/*
RUN ln --symbolic /usr/bin/python3 /usr/bin/python

USER node

COPY --chown=node ../ /home/node/git-hooks/
WORKDIR /home/node/git-hooks/
