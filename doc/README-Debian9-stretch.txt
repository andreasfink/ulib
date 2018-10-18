ulib under Debian9-Stretch
-------------------------

To user ulib with Linux you need to build your own gnustep installation
The ones shipped with the distributions is not supporting automatic 
reference counting because its using the old objc runtime which does not support
ARC.

Here is how to get such a installation up and running under Debian 9 (codename Stretch)


First we need some basic tools and repository's set up

apt-get install --assume-yes\
	apt-transport-https\
	openssh-client\
	vim\
	system-config-lvm\
	dirmngr\
	libsctp1\
	lksctp-tools\
	acpid\
	wget\
	telnet\
	sudo\
	locales-all\
	net-tools

apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xCBCB082A1BB943DB
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C23AC7F49887F95A 
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C208ADDE26C2B797 
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 15CF4D18AF4F7421 
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0D9A1950E2EF0603 
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com EF0F382A1A7B6500
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 15CF4D18AF4F7421
apt-key adv --recv-keys --keyserver keys.gnupg.net A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89
wget -4 -O - http://repo.universalss7.ch/debian/key.asc |apt-key add -

export DEBIAN_VERSION=`cat /etc/debian_version | cut -f1 -d.`
if [ "${DEBIAN_VERSION}" == "9" ]
then
    export DEBIAN_NICKNAME="stretch"
    export BACKPORT_KERNEL_IMAGE=linux-image-4.17.0-0.bpo.1-amd64
else 
    echo "*** UNEXPECTED DEBIAN VERSION ****"
fi

if [ "`cat /proc/cpuinfo | grep KVM`" == "" ]
then
	export MACHINE_TYPE=PHYSICAL
else
	export MACHINE_TYPE=VIRTUAL
fi

echo "deb http://ftp.debian.org/debian ${DEBIAN_NICKNAME}-backports main" > /etc/apt/sources.list.d/backports.list
echo "deb http://repo.universalss7.ch/debian/ ${DEBIAN_NICKNAME} universalss7" > /etc/apt/sources.list.d/universalss7.list


1. You need to install the llvm repository
-------------------------------------------

apt-get install dirmngr
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 15CF4D18AF4F7421

echo "deb http://apt.llvm.org/stretch/ llvm-toolchain-stretch-7 main" > /etc/apt/sources.list.d/llvm.list
echo "deb-src http://apt.llvm.org/stretch/ llvm-toolchain-stretch-7 main" >> /etc/apt/sources.list.d/llvm.list
apt-get update



2. Install depenencies
--------------------------
(run as root or use sudo in front)

 apt-get install build-essential git subversion  \
        libpthread-workqueue0 libpthread-workqueue-dev \
        libblocksruntime0 libblocksruntime-dev \
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
        libc-dev libc++-dev \
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
        libstdc++-6-dev \
        libreadline7 libreadline-dev \
        gobjc-6 gobjc++-6 \
        libgif7 libgif-dev libwings3 libwings-dev libwraster5 libwraster-dev libwutil5 \
        libcups2-dev  libicu57 libicu-dev \
        gobjc++\
        xorg \
        libfreetype6 libfreetype6-dev \
        libpango1.0-dev \
        libcairo2-dev \
        libxt-dev libssl-dev \
        libasound2-dev libjack-dev libjack0 libportaudio2 libportaudiocpp0 portaudio19-dev




Setting some defaults
------------------------------------------------


export CC=clang
export CXX=clang++
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/
    


Download the sourcecode of gnustep and dependencies
---------------------------------------------------

    
    mkdir gnustep
    cd gnustep
    wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.15.tar.gz
    git clone https://github.com/apple/swift-corelibs-libdispatch
    git clone https://github.com/gnustep/scripts
    git clone https://github.com/gnustep/make
    git clone https://github.com/gnustep/libobjc2
    git clone https://github.com/gnustep/base
    git clone https://github.com/gnustep/corebase
    git clone https://github.com/gnustep/gui
    git clone https://github.com/gnustep/back
    ./scripts/install-dependencies
	
	
Lets purge the gcc stuff
apt-get purge libblocksruntime-dev libblocksruntime0
apt-get purge libobjc


4. Build dependencies
    tar -xvzf libiconv-1.15.tar.gz
    cd libiconv-1.15
    ./configure
    make
    make install
    cd ..

    cd swift-corelibs-libdispatch
    mkdir build
    cd build
    cmake .. -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++
    make
    make install
    

5. install gnustep-make

    cd make
    #export OBJCFLAGS="-DEXPOSE_classname_IVARS=1"
    export OBJCFLAGS="-fblocks -fobjc-arc -fobjc-runtime=gnustep-2.0"
    ./configure --with-layout=fhs \
            --disable-importing-config-file \
            --enable-native-objc-exceptions \
            --enable-objc-arc \
            --enable-install-ld-so-conf \
            --with-library-combo=ng-gnu-gnu \
            --with-config-file=/usr/local/etc/GNUstep/GNUstep.conf \
            --with-objc-lib-flag="-l:libobjc.so.4.6 -fblocks" \
            --enable-strict-v2-mode
     make install
     source /usr/local/etc/GNUstep/GNUstep.conf
     cd ..
     

6. install libobjc2 runtime

# if you run into llvm crashes try
#
#	remove below line from  Test/CMakeLists.txt
#       addtest_variants("ForwardDeclareProtocolAccess" "ForwardDeclareProtocolAccess.m;ForwardDeclareProtocol.m" true)
#	remove file Test/ForwardDeclareProtocol.m

	edit CMakeLists.txt and change OLDABI_COMPAT to FALSE
	
	set(OLDABI_COMPAT FALSE CACHE BOOL
        "Enable compatibility with GCC and old GNUstep ABIs")
        
        
    cd libobjc2
    mkdir Build
    cd Build
    cmake .. -DBUILD_STATIC_LIBOBJC=1  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ 
    #-DCMAKE_CXX_FLAGS=-g -DCMAKE_C_FLAGS=-g
    make
    make install
    cd ..
    ldconfig


7. install gnustep-base

    cd base
    export CFLAGS="-fconstant-string-class=NSConstantString"
    ./configure --disable-mixedabi --with-config-file=/usr/local/etc/GNUstep/GNUstep.conf

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
    


