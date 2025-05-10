FROM node

RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
        shfmt \
    && rm --force --recursive /var/lib/apt/lists/*

USER node

COPY --chown=node ../ /home/node/git-hooks/
WORKDIR /home/node/git-hooks/
