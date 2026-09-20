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
3

for U in afink root
do
    if [ "$U" == "afink" ]
    then
        D=~afink
    else
        D=~root
    fi
    G=wheel
    mkdir -p $D/.ssh
    chown $U $D/.ssh
    chmod 700 $D/.ssh
    touch $D/.ssh/authorized_keys
    F=$D/.ssh/authorized_keys
    cp $F $F.bck
    cat $F.bck | grep -v afink > $F
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQRsKAIcCtivT78GatrsODZ+JhSxTwZmtVF8vLhyVID afink@fink-telecom.com" >> $F
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAnneJ/mI8GWL4WdkI5NkrZCXWzKm8BB93K0NY2wdrz3 afink@studio-one.fink.org" >> $F
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsuv+URA9Bfr6cMQgqFcACWWYb93Qn0IdAFz5rw29NZ afink@afink-m3.local" >> $F
    chown $U:$G $D/.ssh/authorized_keys
    chmod 644 $D/.ssh/authorized_keys
done
