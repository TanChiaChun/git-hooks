FROM node

RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
        shfmt \
        shellcheck \
        bats \
        pipx \
        python3 \
        python3-venv \
    && rm --force --recursive /var/lib/apt/lists/*

RUN ln --symbolic /usr/bin/python3 /usr/bin/python

USER node

RUN pipx install poetry
ENV PATH="/home/node/.local/bin:$PATH"

ENV npm_config_prefix=/home/node/.npm-global
ENV PATH="$npm_config_prefix/bin:$PATH"
RUN npm install --global markdownlint-cli \
    && npm cache clean --force

COPY --chown=node poetry.toml /home/node/git-hooks/
COPY --chown=node pyproject.toml /home/node/git-hooks/
WORKDIR /home/node/git-hooks/
RUN poetry sync

COPY --chown=node . /home/node/git-hooks/

SHELL ["/bin/bash", "-o", "errexit", "-o", "pipefail", "-c"]
CMD source './src/ci.sh' && run_ci_bash
