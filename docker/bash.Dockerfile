FROM node

RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
        shfmt \
        shellcheck \
        bats \
        python3-venv \
    && rm --force --recursive /var/lib/apt/lists/*

RUN ln --symbolic /usr/bin/python3 /usr/bin/python

ENV npm_config_prefix=/home/node/.npm-global
ENV PATH="/home/node/.npm-global/bin:$PATH"
RUN npm install --global markdownlint-cli

USER node

COPY --chown=node ../ /home/node/git-hooks/
WORKDIR /home/node/git-hooks/

RUN python -m venv ./venv \
    && ./venv/bin/pip install --requirement ./requirements-dev.txt
