FROM node

RUN ln --symbolic /usr/bin/python3 /usr/bin/python

USER node

ENV npm_config_prefix=/home/node/.npm-global
ENV PATH="/home/node/.npm-global/bin:$PATH"
RUN npm install --global markdownlint-cli \
    && npm cache clean --force

COPY --chown=node . /home/node/git-hooks/
WORKDIR /home/node/git-hooks/

SHELL ["/bin/bash", "-o", "errexit", "-o", "pipefail", "-c"]
CMD source './src/ci.sh' && run_ci_markdown
