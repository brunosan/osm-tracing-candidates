
# coding: utf-8

# In[40]:

#!/usr/bin/python
import sys
import numpy as np
import matplotlib.pyplot as plt

csvfile = sys.argv[1]
csvname= csvfile.split(".")[0]

#Read and ranks tile nodes and requests from top 50k file
# read requests data
#file 0-z 1-x 2-y 3-nodes 4-lat, 5-lon, 6-views, 7-water 8-sat 9-osm

with open( csvfile, "r" ) as txt:
    raw = txt.readlines()
# break each line into z,x,y,count
lines = [ line.replace('\n','').replace(',,',',-1,').split( "," ) for line in raw[1:] ]
print csvfile
print len(raw)," lines."
print "headers",raw[0]
print "First line: ",lines[1]






# In[42]:


plt.figure(figsize=(10,5))
osm=np.array([np.log10(int(line[6])+1) for line in lines ])
sat=np.array([(int(line[7])+1.01) for line in lines ])
rosm=np.array([(int(line[8])+1) for line in lines ])
rsat=np.array([(int(line[9])+1.01) for line in lines ])
rdelta=np.array([int(line[10]) for line in lines ])
plt.scatter(osm,sat,c=rdelta,linewidths=0.3,alpha=0.4)
plt.ylabel("Satellite tile Filesize")
plt.xlabel("Log 10 OSM nodes")
plt.title("Tile node-satellite discrepancy")
#plt.xlim(-0.1,5.6)
#plt.ylim(-0.1,5)
reds = plt.scatter([],[],color=(117/255.,0,0))
greens = plt.scatter([],[],color=(134/255.,255/255.,60/255.) )
blues = plt.scatter([],[],color=(9/255.,27/255.,94/255.))
plt.legend([reds,greens,blues],["Positive","Similar","Negative"],title="Ranking Discrepancy",loc='lower right')
f = open(csvname+'-percentiles.txt', 'w')
f.write("\n".join([str(i)+" -> "+str(int(np.percentile(rdelta,i))) for i in [0,10,20,40,60,80,90,100]]))
print "Writting into:", csvname+'-scatter.png'
plt.savefig(csvname+'-scatter.png')


# In[44]:

print np.percentile(rdelta,10)
print np.percentile(10**osm,10)
print np.percentile(sat,50)


# In[64]:

#0 zxy,z,x,y,lat,lon, 6 osm,satellite,r_osm,r_satellite, 10 delta_rso,osm_timestamp,satellite_timestamp

toptracing=list([line for line in lines if 
                 int(line[10])<=np.percentile(rdelta,99) and 
                 int(line[7])>=np.percentile(sat,50) ])
print len(toptracing), len(lines)
#print toptracing
f = open(csvname+'-candidates.csv', 'w')
f.write(raw[0])
[f.write(",".join(t)+"\n") for t in toptracing]






# In[ ]:



