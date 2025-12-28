FROM node:lts

RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
        shfmt \
        shellcheck \
        bats \
        python3 \
        python3-venv \
    && rm --force --recursive /var/lib/apt/lists/*

RUN ln --symbolic /usr/bin/python3 /usr/bin/python

USER node

COPY --from=astral/uv /uv /bin/

ENV PATH="/home/node/git-hooks/node_modules/.bin:$PATH"
COPY --chown=node package.json /home/node/git-hooks/
WORKDIR /home/node/git-hooks/
RUN npm install \
    && npm install markdownlint-cli2 \
    && npm cache clean --force

COPY --chown=node pyproject.toml /home/node/git-hooks/
RUN uv sync --no-cache

COPY --chown=node --exclude=package.json . /home/node/git-hooks/

SHELL ["/bin/bash", "-o", "errexit", "-o", "pipefail", "-c"]
CMD source './src/ci.sh' && run_ci_bash
