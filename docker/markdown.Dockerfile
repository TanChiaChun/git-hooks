FROM node

ARG REPO_NAME=repo
ARG CI_SCRIPT_PATH=./git-hooks/src/ci.sh
ENV CI_SCRIPT_PATH=$CI_SCRIPT_PATH

RUN ln --symbolic /usr/bin/python3 /usr/bin/python

USER node

ENV PATH="/home/node/git-hooks/node_modules/.bin:$PATH"
WORKDIR /home/node/$REPO_NAME/
RUN npm install markdownlint-cli \
    && npm cache clean --force

COPY --chown=node . /home/node/$REPO_NAME/

SHELL ["/bin/bash", "-o", "errexit", "-o", "pipefail", "-c"]
CMD source "$CI_SCRIPT_PATH" && run_ci_markdown
