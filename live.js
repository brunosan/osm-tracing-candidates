#!/usr/bin/env node

//get features from a live vector map
//input specifies tile. E.g. 

var request = require('request');
var vtfx = require('vtfx');
var zlib = require('zlib');
var path = require('path');
var fs = require('fs');
var mapnik = require('mapnik');
var flatten = require('flatten');
var tilebelt = require('tilebelt');

if (!process.env.MapboxAccessToken) throw new Error('MapboxAccessToken env var must be set');

var zxy = process.argv[2] || '';
if (!/^\d+\/\d+\/\d+$/.test(zxy)) {
  console.log('Usage: ./live.js {z}/{x}/{y}');
  process.exit(1);
}
var z = parseInt(zxy.split('/')[0]),
    x = parseInt(zxy.split('/')[1]),
    y = parseInt(zxy.split('/')[2]);

var mapid = "mapbox.mapbox-streets-v5" //process.argv[3] || '';


var maxz=14;

xyz=[x,y,z]
function getzmaxxy(xyz, maxz) {
    if (xyz[2]-1 < maxz){
      return(xyz);
    } else {
      return getzmaxxy(tilebelt.getParent(xyz),maxz);   
    }           
}
var zmaxxyz=getzmaxxy(xyz, maxz);
var xmaxz=zmaxxyz[0];
var ymaxz=zmaxxyz[1];
var maxzxy=[maxz,xmaxz,ymaxz].join('/')

//console.log(zmaxxyz,'https://a.tiles.mapbox.com/v4/' + mapid + '/' + maxzxy + '.vector.pbf?access_token=' + process.env.MapboxAccessToken);


var total_nodes = 0;

request({
  uri: 'https://a.tiles.mapbox.com/v4/'+mapid+'/' + maxzxy + '.vector.pbf?access_token=' + process.env.MapboxAccessToken,
  encoding: null
}, function(err, res, zbody) {
  if (res.statusCode == '404') {
    console.log('-1');
    return
  } else {
  if (err) throw err; 
  zlib.gunzip(zbody, function(err, body) {
    if (err) throw err;
    //var vt = vtfx.decode(body);
    //console.log("Tile: %j", vt.layers.length);
    var input_vt = new mapnik.VectorTile(maxz,xmaxz,ymaxz);
    input_vt.setData( body );
    input_vt.parse();
    var output_vt = new mapnik.VectorTile(z,x,y);
    output_vt.composite([input_vt], {buffer_size:0} );
    output_vt.parse();
    //console.log(output_vt);
    try{
      var layers = output_vt.toGeoJSON('__array__');
      for (var i = 0; i < layers.length; i++) {
        var layer = layers[i];
        for (var j = 0; j < layer.features.length; j++) {
          flat=flatten(layer.features[j].geometry.coordinates);
          total_nodes += flat.length;
        }
      }
    } catch (e) {
      //console.log("emtpy");
      console.log('-1');
      return
    }
    console.log(total_nodes);
  });
}
  
});

