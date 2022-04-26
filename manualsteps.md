# Setup for local testing

## 1. Setting up a mysql database as source db

### 1.1 setup a database
For now I did use a free-tier mysql database @AWS.
You can start a local mysql database with this command:
```bash
docker run -p 3306:3306 --name mysql -v "$PWD/data":/var/lib/mysql -e MYSQL_ROOT_PASSWORD=secret -d mysql:latest --binlog_format=ROW --binlog_expire_logs_seconds=172800

#or once it is already create
docker start mysql

# to inspect
docker inspect mysql

# to stop
docker stop mysql

# to connect
mysql -h 127.0.0.1 -u root -p -v
```
This will use a database store in the ./data/ directory on you localhost.

### 1.2 create a database, user and table
``` sql
CREATE DATABASE test;
CREATE USER 'myuser'@'%' IDENTIFIED WITH mysql_native_password BY 'mypassword';
GRANT ALL PRIVILEGES ON *.* TO 'myuser'@'%';
--GRANT REPLICATION SLAVE, REPLICATION CLIENT, SELECT ON *.* TO 'myuser'@'%';
FLUSH PRIVILEGES;
quit;
```
now we can logon with the new user
```bash
mysql -h 127.0.0.1 -u myuser -p -v
```

``` sql
USE test;
CREATE TABLE `contract` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `contractnumber` varchar(45) DEFAULT NULL,
  `product` varchar(45) DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idcontract_UNIQUE` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE products (
    `product_code` VARCHAR(10),
    `product_description` VARCHAR(256),  
    PRIMARY KEY (product_code));

INSERT INTO test.products (product_code, product_description) VALUES ('ALA', 'Aflossingsvrij, Lineair en Annuiteiten');
INSERT INTO test.products (product_code, product_description) VALUES ('TOP', 'Een TOP product');

COMMIT;
```

### 1.3 set the right binlog parameters on AWS

For a standalone mysqld, using above parameters to start it. When running the mysql on RDS of AWS, read the following:

In order to get this working, you need to create your own mysql parameter group in which the binlog format is set to ROW.

Use also this script to set the retention time of the binlog:
```sql

CALL mysql.rds_show_configuration;

SET SQL_SAFE_UPDATES=0;
call mysql.rds_set_configuration('binlog retention hours', 48);
SET SQL_SAFE_UPDATES=1;
commit;
```

### 1.4 Test by adding rows to the contract table
``` sql
INSERT INTO `test`.`contract` (`contractnumber`, `product`, `amount`) VALUES ("12345679", "ALA", 200000.00);
INSERT INTO `test`.`contract` (`contractnumber`, `product`, `amount`) VALUES ("12345678", "TOP", 150000.00);
commit;
```

# 2. Use localstack to test AWS locally
See [here](https://github.com/localstack/localstack) for installing localstack

start localstak in docker:
``` bash
DEBUG=1 LAMBDA_EXECUTOR=docker SERVICES=kinesis,cloudwatch,lambda,dynamodb localstack start --docker
```

## 2.1 Create 2 DynamoDB's
run the following commands to create two tables in dynamodb
``` bash
aws --endpoint-url=http://localhost:4566 dynamodb create-table \
    --table-name contract1 \
    --attribute-definitions AttributeName=contractnumber,AttributeType=S \
    --key-schema AttributeName=contractnumber,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5


# to read all records in a dynamodb use:
aws --endpoint-url=http://localhost:4566 dynamodb scan --table-name=contract1
```

## 2.2 Create the consumer lambda
```bash
aws --endpoint-url=http://localhost:4566 lambda create-function \
    --function-name=processKinesisStreamContractChange1 \
    --runtime=nodejs6.10 \
    --role=r1 \
    --handler=index.handler \
    --zip-file fileb://processKinesisStreamContractChange1.local.zip

#And
aws --endpoint-url=http://localhost:4566 lambda create-function \
    --function-name=processKinesisStreamContractChange2 \
    --runtime=nodejs6.10 \
    --role=r1 \
    --handler=index.handler \
    --zip-file fileb://processKinesisStreamContractChange2.local.zip

# to test:
aws --endpoint-url=http://localhost:4566 lambda invoke \
    --function-name=processKinesisStreamContractChange1 \
    outfile=out.txt

aws --endpoint-url=http://localhost:4566 lambda invoke \
    --function-name=processKinesisStreamContractChange1 \
    outfile=out.txt \
    --payload='{ "Records": [ { "kinesis": { "partitionKey": "partitionKey-03", "kinesisSchemaVersion": "1.0", "data": "ewogICAgImFjdGlvbiI6ICJJbnNlcnQiLAogICAgInR5cGUiOiAiY29udHJhY3QiLAogICAgImlkIjogODgKfQ==", "sequenceNumber": "49545115243490985018280067714973144582180062593244200961", "approximateArrivalTimestamp": 1428537600 }, "eventSource": "aws:kinesis", "eventID": "shardId-000000000000:49545115243490985018280067714973144582180062593244200961", "invokeIdentityArn": "arn:aws:iam::EXAMPLE", "eventVersion": "1.0", "eventName": "aws:kinesis:record", "eventSourceARN": "arn:aws:kinesis:EXAMPLE", "awsRegion": "eu-central-1" } ] }'

#to update a lambda:
aws --endpoint-url=http://localhost:4566 dynamodb create-table --table-name contract1 --attribute-definitions AttributeName=contractnumber,AttributeType=S --key-schema AttributeName=contractnumber,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```
## 2.2 Create the KinesisStream
Create the kinesisStream:
``` bash
aws --endpoint-url=http://localhost:4566 kinesis create-stream \
    --stream-name contractChanges \
    --shard-count 1

# to show the streams:
aws --endpoint-url=http://localhost:4566 kinesis list-streams

# and to describe the stream:
aws --endpoint-url=http://localhost:4566 kinesis describe-stream --stream-name contractChanges

```
And link the lambda as consumer:
``` bash
aws --endpoint-url=http://localhost:4566 lambda create-event-source-mapping \
    --function-name processKinesisStreamContractChange1 \
    --enabled \
    --batch-size 500 \
    --starting-position AT_TIMESTAMP \
    --starting-position-timestamp 1541139109 \
    --event-source-arn arn:aws:kinesis:eu-central-1:000000000000:stream/contractChanges

# sme for the second lambda:
aws --endpoint-url=http://localhost:4566 lambda create-event-source-mapping \
    --function-name processKinesisStreamContractChange2 \
    --enabled \
    --batch-size 500 \
    --starting-position AT_TIMESTAMP \
    --starting-position-timestamp 1541139109 \
    --event-source-arn arn:aws:kinesis:eu-central-1:000000000000:stream/contractChanges

#test de stream by:
aws --endpoint-url=http://localhost:4566 kinesis put-record \
    --stream-name contractChanges \
    --partition-key 'bla' \
    --data '
    { "action":  "Insert",
      "type":  "contract",
      "id": 87
    }'


```
