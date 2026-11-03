FROM node:lts

COPY package.json package-lock.json /home/node/repo/
WORKDIR /home/node/repo/
RUN npm ci \
  && npm cache clean --force

RUN npx playwright install --with-deps

COPY . /home/node/repo/

CMD ["npx", "playwright", "test"]
