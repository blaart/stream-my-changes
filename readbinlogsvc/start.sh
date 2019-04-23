#!/bin/sh
cp -r /setup/.aws /root/.
>&2 echo nc -z $MYSQL_HOST 3306
while ! nc -z $MYSQL_HOST 3306; do
    >&2 echo "MySql is unavailable - sleeping"
    sleep 3;
done
node /usr/src/app/index.js
