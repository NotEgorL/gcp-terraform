FROM ubuntu:20.04
RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install curl gnupg2 -y
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg |  apt-key add -

RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt update -y && apt install yarn -y

COPY nodejs-test-webapp /
COPY ormconfig.json .
# graphql-ts-server-boilerplate
#RUN cd graphql-ts-server-boilerplate
RUN yarn
CMD ["usr/bin/yarn","start"]