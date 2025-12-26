FROM node:lts

USER node

COPY --chown=node package.json package-lock.json /home/node/repo/
WORKDIR /home/node/repo/
RUN npm ci \
    && npm cache clean --force

COPY --chown=node . /home/node/repo/

SHELL ["/bin/bash", "-o", "errexit", "-o", "pipefail", "-c"]
CMD source './git-hooks/src/ci.sh' && run_ci_vue
