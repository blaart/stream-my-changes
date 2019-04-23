var mysql = require('mysql');
var AWS = require('aws-sdk');
var convert = require('xml-js');

AWS.config.update({region: process.env.AWS_REGION});
var ddb = new AWS.DynamoDB({apiVersion: '2012-08-10'});

exports.handler = (event, context, callback) => {
  context.callbackWaitsForEmptyEventLoop = false
  console.dir(event.Records[0].kinesis, {depth : 5});
  var connection = mysql.createConnection({
      host: process.env.MYSQL_HOST,
      user: process.env.MYSQL_USER,
      password: process.env.MYSQL_PASSWORD,
      database: process.env.MYSQL_DATABASE,
  });
  var promises = [];
  for (var i=0;i<event.Records.length;i++) {
      promises.push (new Promise(function(resolve, reject) {
          var record = JSON.parse(Buffer.from(event.Records[i].kinesis.data, 'base64').toString('ascii'));
          console.dir(record);

          var q = `SELECT C.contractnumber, C.amount, C.product, P.product_description
                   FROM contract C, products P
                   WHERE id=${record.id} and C.product = P.product_code;`
          console.log('query: ' + q);
          connection.query(q, function (error, results, fields) {
              if (error) {
                  connection.destroy();
                  throw error;
              } else {
                  // connected!
                  console.log (JSON.stringify(results));
                  // Create the DynamoDB service object
                  const options = {compact: true, ignoreComment: true, spaces: 4};

                  var params = {
                    TableName: 'contract2',
                    Item: {
                      'contractnumber' : results[0].contractnumber,
                      'payload' : convert.js2xml(results[0], options)
                    }
                  };

                  var documentClient = new AWS.DynamoDB.DocumentClient({
                      accessKeyId: 'omit',
                      secretAccessKey: 'omit',
                      endpoint: `http://${process.env.DYNAMODB_HOST}:${process.env.DYNAMODB_PORT}`
                  });

                  documentClient.put(params, function(err, data) {
                      if (err)
                          return reject(err);
                      console.log(`Id ${record.id} stored in dynamoDB`);
                      resolve();
                  });
              }
          });
      }));
  }
  Promise.all(promises)
      .then(function() {
          console.log('Ready, all stored)');
          callback(null, "OK")
      })
      .catch(function(error) {
          console.error;
          callback (error, null);
      });
}
