#!/bin/sh
#
# Finnish Meteorological Institute / Mikko Rauhala (2014)
#
# SmartMet Data Ingestion Module for WW3 Model
#

# Load Configuration
if [ -s /smartmet/cnf/data/ww3.cnf ]; then
    . /smartmet/cnf/data/ww3.cnf
fi

if [ -s ww3.cnf ]; then
    . ww3.cnf
fi

OUT=/smartmet/data/ww3/$AREA
CNF=/smartmet/run/data/ww3/cnf
EDITOR=/smartmet/editor/in

UTCHOUR=`date -u +%H -d '-4 hours'`
RUN=`expr $UTCHOUR / 6 \* 6`
RUN=`printf %02d $RUN`
DATE=`date -u +%Y%m%d${RUN}00 -d '-4 hours'`
DDATE=`date -u +%Y%m%d -d '-4 hours'`
TMP=/smartmet/tmp/data/ww3/$AREA/$DATE
LOGFILE=/smartmet/logs/data/wave${RUN}.log


# Use log file if not run interactively
if [ $TERM = "dumb" ]; then
    exec &> $LOGFILE
fi

mkdir -p $TMP/grb
mkdir -p $OUT/surface/querydata

echo "Analysis time: $DATE"
echo "Model Run: $RUN"

OUTNAME=${DATE}_ww3_$AREA

function runBacground()
{
    downloadStep $1 &
    ((dnum=dnum+1))
    if [ $(($dnum % 6)) == 0 ]; then
	wait
    fi
}

function downloadStep()
{
    step=$(printf '%03d' $1)
    FILE="multi_1.glo_30mext.t${RUN}z.f${step}.grib2"


    if [ ! -s $TMP/grb/${FILE} ]; then
        while [ 1 ]; do
            ((count=count+1))
	    echo "Downloading (try: $count) ${FILE}"
	    /usr/bin/time -f "Downloaded (in %e s) ${FILE}" wget --no-verbose --retry-connrefused --read-timeout=30 --tries=20 -O $TMP/grb/.${FILE} "http://nomads.ncep.noaa.gov/cgi-bin/filter_wave_multi.pl?file=${FILE}&lev_surface=on&var_DIRPW=on&var_PERPW=on&var_HTSGW=on&var_UGRD=on&var_VGRD=on&var_WVDIR=on&var_WVPER=on&var_WVHGT=on&subregion=&leftlon=${LEFT}&rightlon=${RIGHT}&toplat=${TOP}&bottomlat=${BOTTOM}&dir=%2Fmulti_1.$DDATE"

            if [ $? = 0 ] && [ -s $TMP/grb/.${FILE} ]; then break; fi; # check return value, break if successful (0)
            if [ $count = 60 ]; then break; fi; # break if max count
            sleep 60
	done # while 1 
	if [ -s $TMP/grb/.${FILE} ]; then
            mv -f $TMP/grb/.${FILE} $TMP/grb/${FILE}
	fi
    else
        echo Cached ${FILE}
    fi

}

# Download first leg
for i in $(seq $LEG1_START $LEG1_STEP $LEG1_END)
do
    runBacground $i
done

# Download second leg
for i in $(seq $LEG2_START $LEG2_STEP $LEG2_END)
do
    runBacground $i
done

# Wait for the downloads to finish
wait

echo -n "Total size of download: "
du -sh $TMP/grb/

echo "Converting grib files to qd files..."
gribtoqd -c $CNF/wave.cnf -t -p "59,Wave" -o $TMP/${OUTNAME}_surface.sqd.tmp $TMP/grb/

#
# Create querydata totalWind and WeatherAndCloudiness objects
#
echo -n "Creating Wind objects: wave..."
time qdversionchange -w 0 7 < $TMP/${OUTNAME}_surface.sqd.tmp > $TMP/${OUTNAME}_surface.sqd
echo "done"

#
# Copy files to SmartMet Workstation and SmartMet Production directories
#

if [ -s $TMP/${OUTNAME}_surface.sqd ]; then
    echo -n "Compressing..."
    bzip2 -k $TMP/${OUTNAME}_surface.sqd
    echo "done"

    echo -n "Copying file to SmartMet Production..."
    mv -f $TMP/${OUTNAME}_surface.sqd $OUT/surface/querydata/${OUTNAME}_surface.sqd
    mv -f $TMP/${OUTNAME}_surface.sqd.bz2 $EDITOR/
    echo "done"
    echo "Created files: ${OUTNAME}_surface.sqd"
fi

rm -rf $TMP
