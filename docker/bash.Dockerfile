FROM node

USER node

COPY --chown=node ../ /home/node/git-hooks/
WORKDIR /home/node/git-hooks/
