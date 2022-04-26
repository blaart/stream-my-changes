var ZongJi = require('zongji');
var AWS = require('aws-sdk');
const util = require('util');

var zongji = new ZongJi({
    host: process.env.MYSQL_HOST,
    port: '3306',
    user: 'myuser',
    password: 'mypassword',
});

zongji.on('binlog', function(evt) {
    if (evt.getTypeName() == 'WriteRows') {
        console.log('New rows:\n' + util.inspect(evt.rows, {showHidden: false, depth: null}))
        var stream = { action:  "Insert",
                       type:    "contract",
                       id: evt.rows[0].id
                   };
        var kinesis = new AWS.Kinesis({
            // region: 'eu-central-1',
            region: process.env.AWS_REGION,
            endpoint: `http://${process.env.KINESIS_HOST}:${process.env.KINESIS_PORT}`
            // endpoint: 'localhost:4566'
        });
        var record = {
          Data: JSON.stringify(stream),
          PartitionKey: 'bla'
        };
        var records = [];
        records.push(record);
        var recordsParams = {
          Records: records,
          StreamName: 'contractChanges'
        };

        kinesis.putRecords(recordsParams, function(err, data) {
          if (err) {
            console.log(err);
          }
          else {
            console.log(util.format("Sent %d records with %d failures ..", records.length, data.FailedRecordCount));
          }
        });
    }

    if (evt.getTypeName() == 'UpdateRows') {
        console.log('Update rows:\n' + util.inspect(evt.rows, {showHidden: false, depth: null}))
        console.log('ID: ' + evt.rows[0].after.id);
    }

    if (evt.query != 'BEGIN') {
        //console.log(query);
    }
});

console.log ('starting polling')
zongji.start({
  includeEvents: ['tablemap','writerows', 'updaterows', 'deleterows'],
  includeSchema: {'mydb' : ['contract']},
});

// setTimeout(function(){
//     console.log('Stopping polling');
//     zongji.stop();
//     // connection.end();
// }, 250000);
