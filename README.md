## Goal

Make a list of places using the discrepancy between OSM nodes ranking and satellite tile filesize ranking gives.


Ref: https://www.mapbox.com/blog/osm-tracing-candidates/



### Install

```js
npm install
```


### Usage


Set variables
```sh
#Mapbox token to make the tile requests
export MapboxAccessToken="<TOKEN>"
#AWS bucket to updload the result
export AWSbucket="<BUCKET>"
```


Create the ranking 
```sh
./query-json.sh area.json zoom

#if region is large, tmux it
tmux
./query-json.sh GI.geojson 16 &> log.out
#detach with ctrl+b d
tail -f log.out
```
Process to create the scatter plots and list
```sh
process.py output.csv
```