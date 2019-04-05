#!/bin/bash
echo $#
if [ $# != 1 ] ; then
    echo "Defaulting to 1200 baud."
    baud=1200
else
    baud=$1
fi
exec stdbuf -o0 bash -i |& stdbuf -i0 -o0 -e0 ./baudsim $baud
