#!/bin/bash


#import places csv into psql
file="`pwd`/sl/sl_populatedplaces_p.txt"
name="sl"
psql -U postgres -c "drop table $name;"
psql -U postgres -c "create table $name (\
RC       char(40),\
UFI     char(40),\
UNI     char(40),\
LAT     double precision,\
LONG    double precision,\
DMS_LAT double precision,\
DMS_LONG        double precision,\
MGRS    char(40),\
JOG     char(40),\
FC      char(40),\
DSG     char(40),\
PC      char(40),\
CC1     char(40),\
ADM1    char(40),\
POP     char(40),\
ELEV    char(40),\
CC2     char(40),\
NT      char(40),\
LC      char(40),\
SHORT_FORM      char(40),\
GENERIC char(40),\
SORT_NAME_RO    char(40),\
FULL_NAME_RO    char(40),\
FULL_NAME_ND_RO char(40),\
SORT_NAME_RG    char(40),\
FULL_NAME_RG    char(40),\
FULL_NAME_ND_RG char(40),\
NOTE    char(40),\
MODIFY_DATE     char(40),\
DISPLAY char(40),\
NAME_RANK       char(40),\
NAME_LINK       char(40),\
TRANSL_CD       char(40),\
NM_MODIFY_DATE char(40));"


psql -U postgres -c "copy $name from '$file' DELIMITER '	' CSV HEADER;"