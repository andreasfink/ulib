#!/bin/sh

pkg install bash
ln -s /usr/local/bin/bash /usr/bin/bash
ln -s /usr/local/bin/bash /bin/bash
pkg install gnustep
pkg install clang
pkg install autoconf
pkg install pkgconf
pkg install sudo
pkg install cmake
pkg install automake
pkg install git
pkg install gmake
pkg install libzmq4
pkg install openssl40
pkg install postgresql-libpqxx
pkg install mariadb123-client
pkg install dmidecode

/etc/periodic/weekly/310.locate
PATH=/opt/buildtools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/GNUstep/System/Tools
PKG_CONFIG_PATH=/usr/local/lib/pkg-config:/usr/libdata/pkgconfig:/usr/local/libdata/pkgconfig/

export PATH
export PKG_CONFIG_PATH
