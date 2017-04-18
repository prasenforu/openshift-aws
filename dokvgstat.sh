#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export $PATH
to=`vgs | grep docker-vg | awk '{print $6}' | sed 's/g/ g/;s/m/ m/;s/t/ t/'`
fr=`vgs | grep docker-vg | awk '{print $7}' | sed 's/g/ g/;s/m/ m/;s/t/ t/'`
echo $to | awk '{if($2 == "t") {a = ($1*1024*1024*1024); print "DOC_VG_Total " a;}}'
echo $to | awk '{if($2 == "g") {a = ($1*1024*1024); print "DOC_VG_Total " a;}}'
echo $to | awk '{if($2 == "m") {a = ($1*1024); print "DOC_VG_Total " a;}}'
echo $fr | awk '{if($2 == "t") {b = ($1*1024*1024*1024); print "DOC_VG_Free " b;}}'
echo $fr | awk '{if($2 == "g") {b = ($1*1024*1024); print "DOC_VG_Free " b;}}'
echo $fr | awk '{if($2 == "m") {b = ($1*1024); print "DOC_VG_Free " b;}}'
