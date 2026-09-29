#!/bin/sh

/etc/periodic/weekly/310.locate
PATH=/opt/buildtools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/GNUstep/System/Tools
PKG_CONFIG_PATH=/usr/local/lib/pkg-config:/usr/libdata/pkgconfig:/usr/local/libdata/pkgconfig/

export PATH
export PKG_CONFIG_PATH

pkg install bash
ln -s /usr/local/bin/bash /usr/bin/bash
ln -s /usr/local/bin/bash /bin/bash
pkg install gnustep
pkg install FreeBSD-clang-15.1p2
pkg install FreeBSD-clang-dbg-15.1p2
pkg install FreeBSD-clang-dev-15.1p1
pkg install autoconf
pkg install pkgconf
pkg install sudo
pkg install cmake
pkg install automake
pkg install git
pkg install gmake
pkg install libzmq4
pkg install postgresql-libpqxx
pkg install mariadb123-client
pkg install dmidecode
pkg install libiconv-1.18_1
pkg install libuuid-2.42.1
pkg install libtool


if [ ! -f /usr/local/lib/libzmq.a ]
then
		mkdir -p build/
		pushd build
        git clone https://github.com/zeromq/libzmq.git
        cd libzmq
        ln -s /usr/local/bin/libtool ./libtool
        ./autogen.sh
        CFLAGS=-fPIC CXXFLAGS=-fPIC MAKE="gmake" ./confiugre --enable-static --enable-shared
        gmake -j20
        sudo gmake install
        popd
fi

if [ ! -f /usr/local/lib/libcrypto.a ]
then
		mkdir -p build/
		pushd build
		git clone https://github.com/openssl/openssl.git
        cd openssl
        ./autogen.sh
        CFLAGS=-fPIC CXXFLAGS=-fPIC MAKE="gmake" ./Configure
        gmake -j20
        sudo gmake install
        popd
fi



/etc/periodic/weekly/310.locate
PATH=/opt/buildtools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/GNUstep/System/Tools
PKG_CONFIG_PATH=/usr/local/lib/pkg-config:/usr/libdata/pkgconfig:/usr/local/libdata/pkgconfig/

export PATH
export PKG_CONFIG_PATH
