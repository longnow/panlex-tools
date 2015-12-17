var express = require('express');
var taxonfinder = require('taxonfinder');

var app = express();

app.get('/', function (req, res) {
    if (req.query.text === undefined) res.status(409).end();
    else res.json(taxonfinder.findNamesAndOffsets(req.query.text));
});

var server = app.listen(3000, function () {
  var host = server.address().address;
  var port = server.address().port;

  console.log('Example app listening at http://%s:%s', host, port);    
});