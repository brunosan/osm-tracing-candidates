#!/usr/bin/env node
 
//given a z x y from input, return the number of nodes
//as read from an mbtile file within the tile 
//E.g. ./index.js file.mbtile z x y

var request = require('request');
var vtfx = require('vtfx');
var zlib = require('zlib');
var path = require('path');
var fs = require('fs');
 
//console.log(process.argv);

var mbfile=process.argv[2],
    z= process.argv[3],
    x= process.argv[4],
    y= process.argv[5];
//console.log("z/x/y", z,x,y, mbfile);
 
var total_nodes = 0;
 
var MBTiles = require('mbtiles');
new MBTiles(mbfile, function(err, mbtiles) {
    mbtiles.getTile(z, x, y, function(err, data) {  
        zlib.unzip(data, function(err, body) {
        if (err) throw err;
        var vt = vtfx.decode(body);
        //console.log("Tile: %j", vt);
        for (var i = 0; i < vt.layers.length; i++) {
            // To inspect vector tile data:
            //console.log("Tile: %j", vt.layers[i].features.length);
            //console.log(i,"Tile: %j", vt.layers[i]);
            for (var j = 0; j < vt.layers[i].features.length; j++) {
              total_nodes += vt.layers[i].features[j].geometry.length;
            }
        }
        console.log(total_nodes);
    });
    });
});