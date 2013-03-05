#!/bin/bash -xe

export R_LIBS_USER=$R_LIBS_USER${R_LIBS_USER:+:}$HOME/R

export DISPLAY=:0


OLDHOME=$HOME
export HOME=$(mktemp -d)
#mkdir -p $HOME/.vnc
#chmod go-rwx $HOME/.vnc
#cp $OLDHOME/.vnc/passwd $HOME/.vnc/

HOME=$OLDHOME vnc4server -kill $DISPLAY ||:
HOME=$OLDHOME vnc4server -name Tribler -geometry 1280x1024 $DISPLAY

sleep 2
openbox &
OBOX_PID=$!
sleep 1

pwd

cd tribler


#Build swift
cd Tribler/SwiftEngine
make -j4
cp swift ../../
cd ../..
#EO Build swift


#Run the tests
TESTDIR=Tribler/Test

echo "nosetests --with-xcoverage --xcoverage-file=$PWD/coverage.xml  --with-xunit --all-modules --traverse-namespace --cover-package=Tribler --cover-inclusive $TESTDIR/test_remote_search.py" > process_list.txt


mkdir -p output
../experiments/scripts/process_guard.py process_list.txt output 30 1 ||:


ESCAPED_PATH=$(echo $PWD| sed 's~/~\\/~g')
sed -i 's/<!-- Generated by coverage.py: http:\/\/nedbatchelder.com\/code\/coverage -->/<sources><source>'$ESCAPED_PATH'<\/source><\/sources>/g' coverage.xml

#Kill everything
kill $OBOX_PID ||:
sleep 1
if [ -e /proc/$OBOX_PID ]; then
    sleep 5
    kill -9 $OBOX_PID ||:
fi

HOME=$OLDHOME vnc4server -kill $DISPLAY ||:

R --no-save --quiet --args $XMIN $XMAX < $WORKSPACE/experiments/scripts/r/install.r
R --no-save --quiet --args $XMIN $XMAX < $WORKSPACE/experiments/scripts/r/cputimes.r 

