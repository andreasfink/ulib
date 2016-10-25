#!/bin/bash
# Detects which OS and if it is Linux then it will detect which Linux Distribution.

OS=`uname -s`
REV=`uname -r`
MACH=`uname -m`

if [ "${OS}" = "Darwin" ]
then
	echo "osx"
elif [ "${OS}" = "SunOS" ]
then
	echo "solaris-${ARCH}"
elif [ "${OS}" = "AIX" ]
then
	echo "aix"
elif [ "${OS}" = "Linux" ]
then	
        if [ -f /etc/redhat-release ]
        then
        	echo "redhat-${MACH}"
        elif [ -f /etc/SuSE-release ]
        then
        	echo "suse-${MACH}"
        elif [ -f /etc/mandrake-release ]
        then
        	echo "mandrake-${MACH}"
        elif [ -f /etc/debian_version ] 
        then
        	echo "debian-${MACH}"
		fi
fi

