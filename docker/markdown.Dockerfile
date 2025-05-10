FROM node

USER node

ENV npm_config_prefix=/home/node/.npm-global
ENV PATH="/home/node/.npm-global/bin:$PATH"

RUN npm install --global markdownlint-cli

COPY --chown=node ../ /home/node/git-hooks/
WORKDIR /home/node/git-hooks/
