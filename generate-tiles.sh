#!/bin/bash

#Given a csv file with tile info, generate a valid jseon file with the properties

csv=$1
zoom=$2
export name=${csv%.*}
set -x 

start='{
  "type": "FeatureCollection",
  "features": [
      '
end=']}'

echo $start > $name.tiles.geojson
tail +2 $csv   | \
awk -v FS="," '{print "\{\"tile\": ["$3","$4","$2"],\"properties\":\{\"delta\": "$9",\"rtomtom\": "$8",\"rosm\": "$7",\"tomtom\": "$6",\"osm\": "$5"\}\}"}' | mercantile shapes | \
sed -e 's/Feature\"\}/Feature\"\},/g' \
>> $name.tiles.geojson

tail -1 $csv   | \
awk -v FS="," '{print "\{\"tile\": ["$3","$4","$2"],\"properties\":\{\"delta\": "$9",\"rtomtom\": "$8",\"rosm\": "$7",\"tomtom\": "$6",\"osm\": "$5"\}\}"}' | mercantile shapes  \
>> $name.tiles.geojson
echo $end >> $name.tiles.geojson