#!/bin/sh
# cp -r /root/.aws /root/.

#sleep until the services on localstack docker are ready
until aws --endpoint-url=http://awssvc:4569 dynamodb list-tables; do
  >&2 echo "DynamoDB is unavailable - sleeping"
  sleep 1
done

#create the dynamodb's
aws --endpoint-url=http://awssvc:4569 dynamodb create-table \
    --region eu-central-1 \
    --table-name contract1 \
    --attribute-definitions AttributeName=contractnumber,AttributeType=S \
    --key-schema AttributeName=contractnumber,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

aws --endpoint-url=http://awssvc:4569 dynamodb create-table \
    --table-name contract2 \
    --attribute-definitions AttributeName=contractnumber,AttributeType=S \
    --key-schema AttributeName=contractnumber,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

until aws --endpoint-url=http://awssvc:4574 lambda list-functions; do
  >&2 echo "Lambda is unavailable - sleeping"
  sleep 1
done

#create the lambda's
aws --endpoint-url http://awssvc:4574 lambda create-function \
    --function-name processKinesisStreamContractChange1 \
    --runtime nodejs6.10 \
    --role r1 \
    --handler index.handler \
    --environment Variables="{MYSQL_DATABASE=$MYSQL_DATABASE,
        MYSQL_HOST=$MYSQL_HOST,
        MYSQL_PORT=$MYSQL_PORT,
        MYSQL_USER=$MYSQL_USER,
        MYSQL_PASSWORD=$MYSQL_PASSWORD,
        DYNAMODB_HOST=$DYNAMODB_HOST,
        DYNAMODB_PORT=$DYNAMODB_PORT
    }" \
    --zip-file fileb://lambdaProcessKinesisStreamContractChange1.zip

aws --endpoint-url http://awssvc:4574 lambda create-function \
    --function-name processKinesisStreamContractChange2 \
    --runtime nodejs6.10 \
    --role r1 \
    --handler index.handler \
    --environment Variables="{MYSQL_DATABASE=$MYSQL_DATABASE,
        MYSQL_HOST=$MYSQL_HOST,
        MYSQL_PORT=$MYSQL_PORT,
        MYSQL_USER=$MYSQL_USER,
        MYSQL_PASSWORD=$MYSQL_PASSWORD,
        DYNAMODB_HOST=$DYNAMODB_HOST,
        DYNAMODB_PORT=$DYNAMODB_PORT
    }" \
    --zip-file fileb://lambdaProcessKinesisStreamContractChange2.zip

until aws --endpoint-url=http://awssvc:4568 kinesis list-streams; do
  >&2 echo "Kinesis is unavailable - sleeping"
  sleep 1
done

#create the kinesis streams
aws --endpoint-url=http://awssvc:4568 kinesis create-stream \
    --stream-name contractChanges \
    --shard-count 1

#link the lambda's as consumer of the streams
aws --endpoint-url=http://awssvc:4574 lambda create-event-source-mapping \
    --function-name processKinesisStreamContractChange1 \
    --enabled \
    --batch-size 500 \
    --starting-position AT_TIMESTAMP \
    --starting-position-timestamp 1541139109 \
    --event-source-arn arn:aws:kinesis:us-east-1:000000000000:stream/contractChanges

# sme for the second lambda:
aws --endpoint-url=http://awssvc:4574 lambda create-event-source-mapping \
    --function-name processKinesisStreamContractChange2 \
    --enabled \
    --batch-size 500 \
    --starting-position AT_TIMESTAMP \
    --starting-position-timestamp 1541139109 \
    --event-source-arn arn:aws:kinesis:us-east-1:000000000000:stream/contractChanges
