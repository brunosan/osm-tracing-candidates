#!/usr/bin/env node

//Input is a geojson file and a zoom level
//Output is the list of "x y z" tiles, one per line

var cover = require('tile-cover'),
    fs = require('fs');
		
var filein = __dirname+"/"+process.argv[2];
var zoom = process.argv[3];

var limits = {
    min_zoom: zoom,
    max_zoom: zoom
  }

var json = JSON.parse(fs.readFileSync(filein));
var file = fs.createWriteStream(process.argv[2].split('.')[0]+'-'+zoom+'.tmp');

var number_tiles=0;
json.features.forEach(function(region) {
    //console.log(region.geometry);
    tiles=cover.tiles(region.geometry, limits)
    file.on('error', function(err) { /* error handling */ });
    number_tiles+=tiles.length;
    tiles.forEach(function(v) { file.write(v.join(',') + '\n'); });
    
});

console.log(number_tiles);
file.end();

