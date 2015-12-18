var express = require('express');
var taxonfinder = require('taxonfinder');

var app = express();

app.get('/', function (req, res) {
    if (req.query.text === undefined) res.status(409).end();
    else res.json(taxonfinder.findNamesAndOffsets(req.query.text));
});

var host = 'localhost';
var port = 3000;

var server = app.listen(port, host, function () {
  console.log('taxonfinder-api listening at http://%s:%s', host, port);    
});