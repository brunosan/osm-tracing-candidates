#!/usr/bin/env node

//get features from a live vector map
//input specifies tile. E.g. 

var request = require('request');
var vtfx = require('vtfx');
var zlib = require('zlib');
var path = require('path');
var fs = require('fs');

if (!process.env.MapboxAccessToken) throw new Error('MapboxAccessToken env var must be set');

var zxy = process.argv[2] || '';
if (!/^\d+\/\d+\/\d+$/.test(zxy)) {
    console.log('Usage: ./live.js {z}/{x}/{y}');
    process.exit(1);
}

var mapid= process.argv[3] || '';

console.log('https://a.tiles.mapbox.com/v4/'+mapid+'/' + zxy + '.vector.pbf?access_token=' + process.env.MapboxAccessToken);
var total_features = 0;

request({
    uri: 'https://a.tiles.mapbox.com/v4/mapbox.mapbox-streets-v5/' + zxy + '.vector.pbf?access_token=' + process.env.MapboxAccessToken,
    encoding: null
}, function(err, res, zbody) {
    console.log(res);
    console.log(zbody);
    if (err) throw err;
    zlib.unzip(zbody, function(err, body) {
        if (err) throw err;
        var vt = vtfx.decode(body);

        // To inspect vector tile data:
        console.log(vt);

        for (var i = 0; i < vt.layers.length; i++) {
            total_features += vt.layers[i].features.length;
        }
        console.log(total_features);
    });
});
