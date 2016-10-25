#!/bin/bash
cd "$1"
if [ -h "$3" ]
then
	rm "$3"
fi
if [ -h "$4" ]
then
	rm "$4"
fi
if [ -h "$5" ]
then
	rm "$5"
fi

ln -s $2 $3
ln -s $3 $4
ln -s $4 $5
