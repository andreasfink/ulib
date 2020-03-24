ulib under Debian10-buster
-------------------------

To user ulib with Linux you need to build your own gnustep installation
The ones shipped with the distributions is not supporting automatic 
reference counting because its using the old objc runtime which does not support
ARC.

Here is how to get such a installation up and running under Debian 10 (codename Buster)


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
	net-tools

apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xCBCB082A1BB943DB
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C23AC7F49887F95A 
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C208ADDE26C2B797 
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 15CF4D18AF4F7421 
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0D9A1950E2EF0603 
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com EF0F382A1A7B6500
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 15CF4D18AF4F7421
wget -4 -O - http://repo.universalss7.ch/debian/key.asc | apt-key add -

DEBIAN_NICKNAME=sid
DEBIAN_MAIN_VERSION=`cat /etc/debian_version | cut -f1 -d.`
if [ "${DEBIAN_MAIN_VERSION}" = "10" ]
then
	DEBIAN_NICKNAME="buster"
fi
if [ "${DEBIAN_MAIN_VERSION}" = "9" ]
then
	DEBIAN_NICKNAME="stretch"
fi

echo "deb http://ftp.debian.org/debian ${DEBIAN_NICKNAME}-backports main"      > /etc/apt/sources.list.d/backports.list
echo "deb http://repo.universalss7.ch/debian/ ${DEBIAN_NICKNAME} universalss7" > /etc/apt/sources.list.d/universalss7.list


1. You need to install the llvm compiler
-------------------------------------------


echo "deb http://apt.llvm.org/${DEBIAN_NICKNAME}/ llvm-toolchain-${DEBIAN_NICKNAME} main"			> /etc/apt/sources.list.d/llvm.list
echo "deb-src http://apt.llvm.org/${DEBIAN_NICKNAME}/ llvm-toolchain-${DEBIAN_NICKNAME} main"		>> /etc/apt/sources.list.d/llvm.list

apt-get update

apt-get install clang lldb llvm libc++-dev lld python-lldb


2. Install depenencies
--------------------------
(run as root or use sudo in front)

 apt-get install build-essential git subversion  \
        libxml2 libxml2-dev \
        libffi6 libffi-dev\
        libicu-dev \
        libuuid1 uuid-dev uuid-runtime \
        libsctp1 libsctp-dev lksctp-tools \
        libavahi-core7  libavahi-core-dev\
        libavahi-client3 libavahi-client-dev\
        libavahi-common3 libavahi-common-dev libavahi-common-data \
        libgcrypt20 libgcrypt20-dev \
        libtiff5 libtiff5-dev \
        libbsd0 libbsd-dev \
        util-linux-locales \
        locales-all \
        libjpeg-dev \
        libtiff-dev  \
        libcups2-dev  \
        libfreetype6-dev \
        libcairo2-dev \
        libxt-dev \
        libgl1-mesa-dev \
        libpcap-dev \
        python-dev swig \
        libedit-dev libeditline0  libeditline-dev  readline-common \
        binfmt-support libtinfo-dev \
        bison flex m4 wget \
        libicns1    libicns-dev \
        libxslt1.1  libxslt1-dev \
        libxft2 libxft-dev \
        libflite1 flite1-dev \
        libxmu6 libxpm4 wmaker-common\
        libgnutls30 libgnutls28-dev\
        libpng-dev libpng16-16\
        libreadline7 libreadline-dev \
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
        libicu63 libicu-dev \
        ninja-build \
        gobjc gobjc-8 \
        gobjc++ gobjc++-8 \
        libc++1-11 libc++-11-dev \
        default-libmysqlclient-dev \
        libpq-dev libpq5





Download the sourcecode of gnustep and dependencies
---------------------------------------------------

    mkdir gnustep
    cd gnustep
    wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz
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

#   Note libiconf does not build if the compiler is set to clang or the linker to lld.

    wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz
    tar -xvzf libiconv-1.16.tar.gz
    cd libiconv-1.16
    ./configure --enable-static --enable-dynamic
    make
    make install
    cd ..


3. Setting some defaults
------------------------------------------------

export CC="/usr/bin/clang"
export CXX="/usr/bin/clang++"
export PREFIX="/usr/local"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PREFIX}/bin"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig/:${PREFIX}/lib/pkgconfig/"
export RUNTIME_VERSION="gnustep-2.0"
export OBJCFLAGS="-fblocks"
export CFLAGS="-I ${PREFIX}/include -stdlib=libstdc++"
export LDFLAGS="-fuse-ld=/usr/bin/ld.gold"

mkdir -p ${PREFIX}/lib
mkdir -p ${PREFIX}/etc
mkdir -p ${PREFIX}/bin

    cd swift-corelibs-libdispatch
    mkdir build
    cd build
    #cmake .. -DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX} -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=${PREFIX}
    cmake -G Ninja -DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX} -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=${PREFIX} ..
    ninja
    ninja install


5. install libobjc2 runtime

    cd libobjc2
    git submodule init
    git submodule update
    mkdir Build
    cd Build
    /usr/bin/cmake  .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_STATIC_LIBOBJC=1  -DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX} -DCMAKE_INSTALL_PREFIX=${PREFIX}
    make -j8
    make install
    cd ..
    ldconfig



6. install gnustep-make

    cd make

    ./configure \
            --with-layout=fhs \
            --disable-importing-config-file \
            --enable-native-objc-exceptions \
            --enable-objc-arc \
            --enable-install-ld-so-conf \
            --with-library-combo=ng-gnu-gnu \
            --with-config-file=${PREFIX}/etc/GNUstep/GNUstep.conf \
            --with-user-config-file='.GNUstep.conf' \
            --with-user-defaults-dir='GNUstep/Library/Defaults' \
            --with-objc-lib-flag="-l:libobjc.so.4.6"

    make install
    source ${PREFIX}/etc/GNUstep/GNUstep.conf
    cd ..
 
7. install gnustep-base


    cd base
    ./configure --with-config-file=${PREFIX}/etc/GNUstep/GNUstep.conf --disable-mixedabi --with-libiconv-library=/usr/local/lib/libiconv.a
    make -j8
    make install
    ldconfig
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

    cd gnustep/gui
    ./configure
    make -j8
    make install
    ldconfig
    cd ../..

10. install gnustep-back

    cd gnustep/corebase
    ./configure
    make -j8
    make install
    cd ../..

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
    


