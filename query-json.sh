#!/bin/bash

#input is GEOJSON of the region
# e.g. ./query-json.sh DC.geojson 

geojson=$1
zoom=$2
export tablename=$(basename ${geojson%.*})
#export tablename='live'


xtile2long()
{
 xtile=$1
 zoom=$2
 echo "${xtile} ${zoom}" | awk '{printf("%.9f", $1 / 2.0^$2 * 360.0 - 180)}'
} 
export -f xtile2long

ytile2lat()
{
 ytile=$1;
 zoom=$2;
 lat=`echo "${ytile} ${zoom}" | awk -v PI=3.14159265358979323846 '{ 
       num_tiles = PI - 2.0 * PI * $1 / 2.0^$2;
       printf("%.9f", 180.0 / PI * atan2(0.5 * (exp(num_tiles) - exp(-num_tiles)),1)); }'`;
 echo "${lat}";
}
export -f ytile2lat

xtilemid()
{
  start=`xtile2long $1 $2`
  end=`xtile2long $(($1 + 1)) $2`
  echo $(echo  "($start + $end)/2." | bc -l)  
}
export -f xtilemid

ytilemid()
{
  start=`ytile2lat $1 $2`
  end=`ytile2lat $(($1 + 1)) $2`
  echo $(echo  "($start + $end)/2." | bc -l )
}
export -f ytilemid

[ "$MapboxAccessToken" ] || (echo "MapboxAccessToken variable not set" 1>&2 ; exit 1)

export url_pre="https://a.tiles.mapbox.com/v4/brunosan.satellite/"
export url_post=".png?access_token="$MapboxAccessToken


satsize(){
 #set -x 
 zxy=$1
 filesize=`curl -sI $url_pre$zxy$url_post | grep Content-Length | awk '{print $2}'`
 echo $filesize
}
export -f satsize

tile(){
  input=(${1//,/ })
  x=${input[0]}
  y=${input[1]}
  z=${input[2]}
  zxy="$z/$x/$y"
  nodes=$(./live.js $zxy )
  sat=$(satsize  $zxy) 
  lon=$(xtilemid $x $z) 
  lat=$(ytilemid $y $z) 
  psql -U postgres -c "INSERT INTO $tablename (zxy,z,x,y,lat,lon,osm,osm_timestamp,satellite,satellite_timestamp) VALUES ('$zxy',$z,$x,$y,$lat,$lon,$nodes,NOW(),$sat,NOW());" >> /dev/null
  echo -n ",$zxy"
}
export -f tile

SHELL=/bin/bash
psql -U postgres -c "DROP TABLE $tablename;"
psql -U postgres -c "ALTER DATABASE postgres SET synchronous_commit TO OFF;"
psql -U postgres -c " \
CREATE TABLE $tablename (  \
  zxy char(15) UNIQUE, \
  z       integer,    \
  x       integer,    \
  y       integer,    \
  lat     real,    \
  lon     real,    \
  osm   integer DEFAULT -1, \
  satellite   integer DEFAULT -1, \
  r_osm integer, \
  r_satellite integer, \
  delta_rso integer, \
  osm_timestamp TIMESTAMP with time zone, \
  satellite_timestamp TIMESTAMP with time zone \
);"
psql -U postgres -c " \
    CREATE UNIQUE INDEX ${tablename}_idx on $tablename (zxy);"

T="$(date +%s%N)"


tilesfile="`pwd`/$tablename-$zoom.tiles"
if [ -f $tilesfile ]; then
  echo -n "Using list of tiles..."  
else
  echo -n "Creating list of tiles..." 
  ./tile-cover.js $geojson $zoom
fi

echo "done"
echo `cat $tilesfile | wc -l` " tiles."
echo "Querying each tile"
cat $tilesfile | xargs -L1 | parallel -X -n1 --ungroup "tile {} &"
wait $!
wait

psql -U postgres -c "ALTER DATABASE postgres SET synchronous_commit TO ON;"
psql -U postgres -c "COMMIT;"
echo "Waiting 3xwal_writer_delay for async writes..."
sleep 2
echo "all processed should have finsihed"
echo "Adding OSM NODES rank column"
psql -U postgres -c "UPDATE $tablename SET r_osm = rt.r_osm \
       from ( \
			    select zxy,osm,RANK() OVER (ORDER BY osm DESC) as r_osm from $tablename \
			 ) as rt where $tablename.zxy=rt.zxy;"

#-----------
echo "Adding satellite rank column"
psql -U postgres -c "UPDATE $tablename SET r_satellite = rt.r_satellite \
       from ( \
          select zxy,satellite,RANK() OVER (ORDER BY satellite DESC) as r_satellite from $tablename \
       ) as rt where $tablename.zxy=rt.zxy;"
       
echo "Calculating difference in ranking"
psql -U postgres -c "UPDATE $tablename SET delta_rso = r_satellite-r_osm;"

#-----------



psql -U postgres -c "COMMIT;"
echo "EXPORT FILE to $tablename.csv"
psql -U postgres -c "COPY $tablename TO '`pwd`/$tablename.csv' CSV HEADER;"
cat `pwd`/$tablename.csv
echo "Copying to S3"
[ "$AWSbucket" ] || aws s3 cp `pwd`/$tablename.csv $AWSbucket

# Time interval in nanoseconds
T="$(($(date +%s%N)-T))"
# Seconds
S="$((T/1000000000))"
# Milliseconds
M="$((T/1000000))"
wait
printf "Pretty format: %02d:%02d:%02d:%02d.%03d\n" "$((S/86400))" "$((S/3600%24))" "$((S/60%60))" "$((S%60))" "${M}"
