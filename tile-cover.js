#!/usr/bin/env node

//Input is a geojson file and a zoom level
//Output is the list of "x y z" tiles, one per line

var cover = require('tile-cover'),
    fs = require('fs');
		
var filein = __dirname+"/"+process.argv[2];
var zoom = process.argv[3];

var json = JSON.parse(fs.readFileSync(filein));
var limits = {
    min_zoom: zoom,
    max_zoom: zoom
  }
tiles=cover.tiles(json.geometry, limits)

var file = fs.createWriteStream(process.argv[2].split('.')[0]+'-'+zoom+'.tiles');
file.on('error', function(err) { /* error handling */ });
tiles.forEach(function(v) { file.write(v.join(',') + '\n'); });
file.end();