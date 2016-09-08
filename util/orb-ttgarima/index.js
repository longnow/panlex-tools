var express = require('express');
var orbTtgarima = require('./orb-ttgarima');

var app = express();

app.get('/', function (req, res) {
    if (req.query.text === undefined) res.status(409).end();
    else res.json(orbTtgarima(req.query.text));
});

var host = 'localhost';
var port = process.argv[2] || 3000;

var server = app.listen(port, host, function () {
  console.log('orb-ttgarima server listening at http://%s:%s', host, port);
});
