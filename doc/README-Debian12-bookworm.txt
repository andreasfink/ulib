ulib under Debian12-bookworm
-----------------------------

To user ulib with Linux you need to build your own gnustep installation
The ones shipped with the distributions is not supporting automatic
reference counting because its using the old objc runtime which does not support
ARC.

Here is how to get such a installation up and running under Debian 12 (codename Bookworm)


First we need some basic tools and repository's set up

apt-get install --assume-yes \
    apt-transport-https \
    openssh-client \
    vim \
    dirmngr \
    libsctp1 \
    lksctp-tools \
    acpid \
    wget \
    telnet \
    sudo \
    locales-all \
    net-tools \
    libcurl4-openssl-dev \
    gnutls-bin

apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xCBCB082A1BB943DB
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C23AC7F49887F95A
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C208ADDE26C2B797
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 15CF4D18AF4F7421
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0D9A1950E2EF0603
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com EF0F382A1A7B6500
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 15CF4D18AF4F7421

wget -4 -O - http://repo.universalss7.ch/debian/key.asc > /etc/apt/trusted.gpg.d/repo.universalss7.ch.asc
wget -4 -O - http://repo.messagemover.com/debian/key.asc > /etc/apt/trusted.gpg.d/repo.messagemover.com.asc
wget -4 -O - http://repo.gnustep.ch/key.asc > /etc/apt/trusted.gpg.d/repo.gnustep.ch.asc


DEBIAN_NICKNAME=sid
DEBIAN_MAIN_VERSION=`cat /etc/debian_version | cut -f1 -d.`
if [ "${DEBIAN_MAIN_VERSION}" = "12" ]
then
	DEBIAN_NICKNAME="bookworm"
fi
if [ "${DEBIAN_MAIN_VERSION}" = "11" ]
then
	DEBIAN_NICKNAME="bullseye"
fi
if [ "${DEBIAN_MAIN_VERSION}" = "10" ]
then
	DEBIAN_NICKNAME="buster"
fi
if [ "${DEBIAN_MAIN_VERSION}" = "9" ]
then
	DEBIAN_NICKNAME="stretch"
fi

#echo "deb http://ftp.debian.org/debian ${DEBIAN_NICKNAME}-backports main"      > /etc/apt/sources.list.d/backports.list
echo "deb http://repo.universalss7.ch/debian/ ${DEBIAN_NICKNAME} universalss7" > /etc/apt/sources.list.d/universalss7.list


1. Install depenencies
--------------------------
(run as root or use sudo in front)

 apt-get install build-essential git subversion  \
        clang lldb \
        libxml2 libxml2-dev \
        libffi8 libffi-dev\
        libicu-dev \
        libuuid1 uuid-dev uuid-runtime \
        libsctp1 libsctp-dev lksctp-tools \
        libavahi-core7  libavahi-core-dev\
        libavahi-client3 libavahi-client-dev\
        libavahi-common3 libavahi-common-dev libavahi-common-data \
        libgcrypt20 libgcrypt20-dev \
        libtiff6 libtiff-dev \
        libbsd0 libbsd-dev \
        util-linux-locales \
        locales-all \
        libjpeg-dev \
        libcups2-dev  \
        libfreetype6-dev \
        libcairo2-dev \
        libxt-dev \
        libgl1-mesa-dev \
        libpcap-dev \
        python3-dev swig \
        libedit-dev readline-common \
        binfmt-support libtinfo-dev \
        bison flex m4 wget \
        libicns1    libicns-dev \
        libxslt1.1  libxslt1-dev \
        libxft2 libxft-dev \
        libflite1 flite1-dev \
        libxmu6 libxpm4 wmaker-common\
        libgnutls30 libgnutls28-dev gnutls-bin\
        libpng-dev libpng16-16\
        libreadline8 libreadline-dev \
        libgif7 libgif-dev libwings3 libwings-dev  libwutil5 \
        libcups2-dev \
        xorg \
        libfreetype6 libfreetype6-dev \
        libpango1.0-dev \
        libcairo2-dev \
        libxt-dev libssl-dev \
        libasound2-dev libjack-dev libjack0 libportaudio2 libportaudiocpp0 portaudio19-dev \
        wmaker cmake cmake-curses-gui \
        libwraster6 libwraster-dev \
        libicu72 libicu-dev \
        ninja-build \
        gobjc gobjc-12 \
        gobjc++ gobjc++-12 \
        default-libmysqlclient-dev \
        libpq-dev libpq5 curl libcurl4-openssl-dev \
        libzmq3-dev libzmq5 libmariadb-dev \
        libavahi-core-dev libavahi-core7 libsctp-dev libsctp1 libpcap-dev \
        bison flex

Changes for bookworm/sid on risc-v  VisionFive2:
	libffi7 	-> libffi8
	python-dev 	-> python3
	libicu67 	-> libicu71
	lldb 		missing


Download the sourcecode of gnustep and dependencies
---------------------------------------------------

    mkdir gnustep
    cd gnustep
    wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.17.tar.gz
    git clone https://github.com/apple/swift-corelibs-libdispatch
    git clone https://github.com/gnustep/scripts
    git clone https://github.com/gnustep/make
    git clone https://github.com/gnustep/libobjc2
    git clone https://github.com/gnustep/base
    git clone https://github.com/gnustep/corebase
    git clone https://github.com/gnustep/gui
    git clone https://github.com/gnustep/back
    ./scripts/install-dependencies-linux





Build  libiconv
-----------------

#   Note libiconv does not build if the compiler is set to clang or the linker to lld.

    wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.17.tar.gz
    tar -xvzf libiconv-1.17.tar.gz
    cd libiconv-1.17
    CC=gcc LDFLAGS="-fuse-ld=gold" CXX="gcc++" CFLAGS="-fPIC" CPPFLAGS="-fPIC" ./configure --enable-static --enable-dynamic
    make
    make install
    ./libtool --finish /usr/local/lib
    cd ..
#make check

3. Setting some defaults
------------------------------------------------

export CC="/usr/bin/clang"
export CXX="/usr/bin/clang++"
export PREFIX="/usr"
export PATH="/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/sbin:/usr/local/bin"
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
export RUNTIME_VERSION="gnustep-2.0"
export OBJCFLAGS="-fblocks"
export CFLAGS="-I ${PREFIX}/include"
export LDFLAGS="-fuse-ld=gold"

mkdir -p ${PREFIX}/lib
mkdir -p ${PREFIX}/etc
mkdir -p ${PREFIX}/bin

    cd swift-corelibs-libdispatch
    mkdir build
    cd build
    cmake  -DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX} -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=${PREFIX} ..
    make
    make install
#make test


5. install libobjc2 runtime

    cd libobjc2
    git submodule init
    git submodule update
    mkdir Build
    cd Build
    /usr/bin/cmake  .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_STATIC_LIBOBJC=1  -DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX} -DCMAKE_INSTALL_PREFIX=${PREFIX}
    make
    #if you get errors here
    # edif the file CMakeCache.txt  and remove the -stlib... thing in line CMAKE_C_FLAGS:STRING=-I /usr/local/include
    make install
#make test
    cd ..
    ldconfig


6. install gnustep-make

    cd make

    ./configure \
            --with-layout=debian \
            --disable-importing-config-file \
            --enable-native-objc-exceptions \
            --enable-objc-arc \
            --enable-install-ld-so-conf \
            --with-library-combo=ng-gnu-gnu \
            --with-config-file=/etc/GNUstep/GNUstep.conf \
            --with-user-config-file='.GNUstep.conf' \
            --with-user-defaults-dir='GNUstep/Library/Defaults' \
            --with-objc-lib-flag="-l:libobjc.so.4.6"

    make install
    source /etc/GNUstep/GNUstep.conf
    cd ..

7. install gnustep-base


    cd base
    ./configure --with-config-file=/etc/GNUstep/GNUstep.conf \
    	--with-libiconv-library=/usr/local/lib/libiconv.a \
    	--enable-pass-arguments \
    	--enable-zeroconf \
    	--enable-icu \
    	--enable-libdispatch \
    	--enable-nsurlsession\
    	--with-installation-domain=SYSTEM

    make -j8
    make install
    ldconfig
#make check
    cd ..

(for debug version use "make debug=yes" instead of "make")


8. install gnustep-corebase

    cd corebase
    ./configure
    make -j8
    make install
    ldconfig
    cd ..


9.  If you want X11 GUI support in GnuStep install gnustep-gui

    cd gui
    ./configure
    make -j8
    make install
    ldconfig
    cd ..

10. install gnustep-back

    cd corebase
    ./configure
    make -j8
    make install
    cd ..


11. ulib
    git clone http://github.com/andreasfink/ulib
    cd ulib
    ./configure
    make
    make install
    ldconfig
    cd ..

12. webserver sample application
    git clone http://github.com/andreasfink/webserver
    cd webserver
    ./configure
    make
    make install



