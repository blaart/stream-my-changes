FROM python:alpine

ARG CLI_VERSION=1.16.86

RUN apk -uv add --no-cache groff jq less && \
    pip install --no-cache-dir awscli

RUN apk add --update npm
RUN apk add zip

RUN mkdir /setup
RUN mkdir /src

# create lambda processKinesisStreamContractChange1
RUN mkdir /src/processKinesisStreamContractChange1

WORKDIR /src/processKinesisStreamContractChange1
COPY ./src/processKinesisStreamContractChange1/package*.json ./
COPY ./src/processKinesisStreamContractChange1/index.js .

RUN npm install
RUN zip -r /setup/lambdaProcessKinesisStreamContractChange1.zip .


# create lambda processKinesisStreamContractChange2
RUN mkdir /src/processKinesisStreamContractChange2

WORKDIR /src/processKinesisStreamContractChange2
COPY ./src/processKinesisStreamContractChange2/package*.json ./
COPY ./src/processKinesisStreamContractChange2/index.js .

RUN npm install
RUN zip -r /setup/lambdaProcessKinesisStreamContractChange2.zip .


# call the aws service to create the stack
WORKDIR /setup
COPY ./setup.sh .
ENTRYPOINT ["/setup/setup.sh"]
