#!/bin/bash

SYSTEM_TYPE=`uname -s`
if [ "${SYSTEM_TYPE}" == "Darwin" ]
then
	if [ ! -f /usr/local/lib/libiconv.a ]
	then
		sudo installer -pkg libiconv-1.19.pkg -target /
	fi

	if [ ! -f /usr/local/bin/flex ]
	then
		sudo installer -pkg flex-2.6.4.pkg -target /
	fi
	if [ ! -f /usr/local/bin/bison ]
	then
		sudo installer -pkg bison-3.0.4.pkg -target /
	fi
	if [ ! -f /usr/local/lib/mariadb/libmariadbclient.a ]
	then
		sudo installer -pkg libmariadb-3.4.11.pkg /
	fi
	if [ ! -f /usr/local/lib/libpcap.a ]
	then
		sudo installer -pkg libpcap-1.11.0.pkg /
	fi
	if [ ! -f /usr/local/lib/libzmq.a ]
	then
		sudo installer -pkg libzmq5.pkg /
	fi
	if [ ! -f /usr/local/lib/libssl.a ]
	then
		sudo installer -pkg libopenssl-4.1.0.pkg /
	fi
	if [ ! -f /usr/local/pgsql/lib/libpq.a ]
	then
		sudo installer -pkg postgresclient-5.15.pkg /
	fi
fi