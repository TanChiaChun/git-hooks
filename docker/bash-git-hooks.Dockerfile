FROM node

RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
        shfmt \
        shellcheck \
        bats \
        python3-venv \
    && rm --force --recursive /var/lib/apt/lists/*

RUN ln --symbolic /usr/bin/python3 /usr/bin/python

USER node

ENV npm_config_prefix=/home/node/.npm-global
ENV PATH="$npm_config_prefix/bin:$PATH"
RUN npm install --global markdownlint-cli \
    && npm cache clean --force

COPY --chown=node requirements-dev.txt /home/node/git-hooks/
WORKDIR /home/node/git-hooks/
RUN python -m venv ./venv \
    && ./venv/bin/pip install --requirement './requirements-dev.txt' \
    && rm --force --recursive "$(./venv/bin/pip cache dir)"

COPY --chown=node . /home/node/git-hooks/

SHELL ["/bin/bash", "-o", "errexit", "-o", "pipefail", "-c"]
CMD source './src/ci.sh' && run_ci_bash
