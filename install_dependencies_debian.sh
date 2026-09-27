#!/bin/bash

SYSTEM_TYPE=`uname -s`
if [ "${SYSTEM_TYPE}" == "Linux" ]
then
	if [ ! -f /usr/local/lib/libiconv.a ]
	then
	
		mkdir -p build/
		pushd build
		if [ ! -f build/libiconv-1.19.tar.gz ]
		then
			wget https://mirror.init7.net/gnu/libiconv/libiconv-1.19.tar.gz
		fi
		if [ -d libiconv-1.19 ]
		then
			rm -rf libiconv-1.19
		fi
		tar -xvzf libiconv-1.19.tar.gz
		cd libiconv-1.19
		./configure --enable-static
		make -j20
		sudo make install
		cd ..
		popd
	fi
	
    PCFILE=/usr/local/lib/pkgconfig/libiconv.pc
    if [ ! -f "${PCFILE}" ]
    then
        F=/tmp/pcfile.$PPID
        echo '# pkg-config source file' > ${F}
        echo 'prefix=/usr/local' >> ${F}
        echo 'exec_prefix=${prefix}' >> ${F}
        echo 'libdir=${exec_prefix}/lib' >> ${F}
        echo 'includedir=${prefix}/include' >> ${F}
        echo '' >> ${F}
        echo 'Cflags: -I${includedir}' >> ${F}
        echo 'Libs: -L${libdir} -liconv' >> ${F}
        echo '' >> $F
        echo 'Name: libiconv' >> ${F}
        echo 'Description: libiconv' >> ${F}
        echo 'Version: 1.19.0' >> ${F}
        sudo cp $F $PCFILE
    fi
	apt update
	apt install openssl libssl-dev libpq-dev libpq5 libmariadb-dev libmariadb-dev-compat mariadb-client libzmq3-dev libzmq5 uuid-dev libuuid1 autoconf clang
fi
