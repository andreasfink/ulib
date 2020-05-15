ulib under Debian9-Stretch
-------------------------

To user ulib with Linux you need to build your own gnustep installation
The ones shipped with the distributions is not supporting automatic 
reference counting because its using the old objc runtime which does not support
ARC.

Here is how to get such a installation up and running under Debian 9 (codename Stretch)


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

echo "deb http://ftp.debian.org/debian ${DEBIAN_NICKNAME}-backports main"      > /etc/apt/sources.list.d/backports.list
echo "deb http://repo.universalss7.ch/debian/ ${DEBIAN_NICKNAME} universalss7" > /etc/apt/sources.list.d/universalss7.list


1. You need to install the llvm-7 compiler
-------------------------------------------


echo "deb http://apt.llvm.org/stretch/ llvm-toolchain-stretch-7 main"			> /etc/apt/sources.list.d/llvm.list
echo "deb-src http://apt.llvm.org/stretch/ llvm-toolchain-stretch-7 main"		>> /etc/apt/sources.list.d/llvm.list
echo "deb http://apt.llvm.org/stretch/ llvm-toolchain-snapshot main"			>> /etc/apt/sources.list.d/llvm.list
echo "deb-src http://apt.llvm.org/stretch/ llvm-toolchain-snapshot main"		>> /etc/apt/sources.list.d/llvm.list
apt-get update

apt-get install clang-7 lldb-7 llvm-7 libc++-7-dev lld-7 python-lldb-7
apt-get install clang-8 lldb-8 llvm-8 libc++-8-dev lld-8 python-lldb-8
pushd /usr/bin
rm -f clang clang++ clang-cpp lldb
ln -s clang-8 clang
ln -s clang++-8 clang++
ln -s clang-cpp-8 clang-cpp
ln -s lldb-8 lldb
popd

2. Install depenencies
--------------------------
(run as root or use sudo in front)

 apt-get install build-essential git subversion  \
        libxml2 libxml2-dev \
        libffi6 libffi-dev\
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
        libc-dev libc++-dev libc++1 \
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
        libgif7 libgif-dev libwings3 libwings-dev  libwraster-dev libwutil5 \
        libcups2-dev  libicu57 libicu-dev \
        gobjc++\
        xorg \
        libfreetype6 libfreetype6-dev \
        libpango1.0-dev \
        libcairo2-dev \
        libxt-dev libssl-dev \
        libasound2-dev libjack-dev libjack0 libportaudio2 libportaudiocpp0 portaudio19-dev \
         wmaker cmake cmake-curses-gui




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
   # ./scripts/install-dependencies
	
	
Lets purge the gcc stuff in case its installed
----------------------------------------------

apt-get purge libblocksruntime-dev libblocksruntime0


4. Build dependencies

#   Note libiconf does not build if the compiler is set to clang or the linker to lld.

    tar -xvzf libiconv-1.15.tar.gz
    cd libiconv-1.15
    ./configure --enable-static --enable-dynamic
    make
    make install
    cd ..


3. Setting some defaults
------------------------------------------------

export CC="/usr/bin/clang-8"
export CXX="/usr/bin/clang++-8"
export PREFIX="/opt/universalss7"
export PREFIX="/usr/local"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PREFIX}/bin"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig/:${PREFIX}/lib/pkgconfig/"
export RUNTIME_VERSION="gnustep-2.0"
export CPPFLAGS="-L/usr/local/lib -L${PREFIX}/lib"
#export LD="/usr/bin/lld-7"
#export LDFLAGS="-fuse-ld=${LD}"
export OBJCFLAGS="-fblocks"
export CFLAGS="-I ${PREFIX}/include"

mkdir -p ${PREFIX}/lib
mkdir -p ${PREFIX}/etc
mkdir -p ${PREFIX}/bin

    cd swift-corelibs-libdispatch
    mkdir build
    cd build
    cmake .. -DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX} -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=${PREFIX}
    make
    make install
    

    

5. install libobjc2 runtime

    cd libobjc2
    mkdir Build
    cd Build
    cmake ..  -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_STATIC_LIBOBJC=1  -DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX} -DCMAKE_INSTALL_PREFIX=${PREFIX}
    make -j8
    make install
    cd ..
    ldconfig



6. install gnustep-make

    cd make

	cat FilesystemLayouts/fhs | sed 's/^GNUSTEP_DEFAULT_PREFIX=.*$/GNUSTEP_DEFAULT_PREFIX=\/opt\/universalss7/g' > FilesystemLayouts/universalss7


with standard /usr/local layout...
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


    ./configure \
    		--includedir=${PREFIX}/include \
    		--libdir=${PREFIX}/lib \
            --with-layout=universalss7 \
            --disable-importing-config-file \
            --enable-native-objc-exceptions \
            --enable-objc-arc \
            --enable-install-ld-so-conf \
            --with-library-combo=ng-gnu-gnu \
            --with-config-file=${PREFIX}/etc/GNUstep/GNUstep.conf \
            --with-user-config-file='.GNUstep.conf' \
            --with-user-defaults-dir='GNUstep/Library/Defaults' \
          #  --with-objc-lib-flag="-l:libobjc.so.4.6"
    make install
    source ${PREFIX}/etc/GNUstep/GNUstep.conf
    cd ..
 
7. install gnustep-base


    cd base
    ./configure --with-config-file=${PREFIX}/etc/GNUstep/GNUstep.conf --disable-mixedabi --with-libiconv-library=
	echo "# universalss7 libraries" > /etc/ld.so.conf.d/universalss7.conf
	echo "${PREFIX}/lib" >> /etc/ld.so.conf.d/universalss7.conf
	ldconfig


    ./configure  --with-config-file=${PREFIX}/etc/GNUstep/GNUstep.conf  
	make -j8
    make install
    cd ../..
    ldconfig

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
    


