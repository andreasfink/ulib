ulib under Debian9-Stretch
-------------------------

To user ulib with Linux you need to build your own gnustep installation
The ones shipped with the distributions is not supporting automatic 
reference counting because its using the old objc runtime which does not support
ARC.


Here is how to get such a installation up and running under Debian 9 (codename Stretch)

1. Install depenencies
--------------------------
(run as root or use sudo in front)

  Debian 9 Stretch
  --------------------------

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
        llvm clang lldb libclang-dev \
        cmake  gobjc++\
        xorg \
        libfreetype6 libfreetype6-dev \
        libpango1.0-dev \
        libcairo2-dev \
        libxt-dev libssl-dev

    export CC=clang
    export CXX=clang++
    export PATH=/usr/local/bin:$PATH
    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/



3. Download the sourcecode of gnustep and dependencies

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
    /scripts/install-dependencies
	cd ..
	

4. Build dependencies
    cd gnustep
    tar -xvzf libiconv-1.15.tar.gz
    cd libiconv-1.15
    ./configure
    make CFLAGS=-g
    make install
    cd ../..

    cd gnustep/swift-corelibs-libdispatch
    ./autogen.sh
    ./configure
    make CFLAGS=-g
    make install
    cd ../..

5. install gnustep-make

    cd gnustep/make
    export CC=clang
    export CXX=clang++
    export OBJCFLAGS="-DEXPOSE_classname_IVARS=1"
    ./configure --with-layout=fhs \
            --disable-importing-config-file \
            --enable-native-objc-exceptions \
            --enable-objc-nonfragile-abi \
            --enable-objc-arc \
            --with-library-combo=ng-gnu-gnu
     make install
     source /usr/local/etc/GNUstep/GNUstep.conf
     cd ../..
     

6. install libobjc2 runtime


    cd gnustep/libobjc2
    mkdir Build
    cd Build
    cmake .. -DBUILD_STATIC_LIBOBJC=1  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_CXX_FLAGS=-g -DCMAKE_C_FLAGS=-g
    make
    make install
    cd ../../..
    ldconfig

(for debug version add -DCMAKE_BUILD_TYPE=Debug   to the cmake statement )

7. install gnustep-base

    cd gnustep/base
    ./configure CFLAGS="-DEXPOSE_classname_IVARS=1 -g"

    make -j8
    make install
    cd ../..
    ldconfig

(for debug version use "make debug=yes" instead of "make")


8. install gnustep-corebase

    cd gnustep/corebase
    ./configure
    make -j8
    make install
    ldconfig
    cd ../..


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
    


