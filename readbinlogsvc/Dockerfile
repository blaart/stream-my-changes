FROM node:8

WORKDIR /usr/src/app

COPY ./src/package*.json ./
COPY ./src/index.js .
COPY ./start.sh .

RUN apt-get update
RUN apt-get -y install netcat

RUN npm install

CMD [ "/usr/src/app/start.sh" ]
