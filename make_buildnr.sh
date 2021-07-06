#!/bin/bash
BUILDNR=`cat BUILDNR`
BUILDNR=$((BUILDNR+1))
echo "Build Number is $BUILDNR"
echo ${BUILDNR} > BUILDNR
BH="buildnumber.h"
BC="buildnumber.c"
echo "// buildnumber.h" > $BH
echo "// automatically generated by make_buildnumber.sh" >> $BH
echo "// " >> $BH
echo "extern long _g_ulib_buildnumber;" >> $BH

echo "// buildnumber.c" > $BC
echo "// automatically generated by make_buildnumber.sh" >> $BC
echo "// " >> $BC
echo "long _g_ulib_buildnumber = $BUILDNR;" >> $BC
