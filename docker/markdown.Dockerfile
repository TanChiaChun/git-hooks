FROM node

ARG REPO_NAME=repo
ARG CI_SCRIPT_PATH=./git-hooks/src/ci.sh
ENV CI_SCRIPT_PATH=$CI_SCRIPT_PATH

RUN ln --symbolic /usr/bin/python3 /usr/bin/python

USER node

ENV npm_config_prefix=/home/node/.npm-global
ENV PATH="/home/node/.npm-global/bin:$PATH"
RUN npm install --global markdownlint-cli \
    && npm cache clean --force

COPY --chown=node . /home/node/$REPO_NAME/
WORKDIR /home/node/$REPO_NAME/

SHELL ["/bin/bash", "-o", "errexit", "-o", "pipefail", "-c"]
CMD source "$CI_SCRIPT_PATH" && run_ci_markdown
