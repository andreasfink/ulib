Gnustep under FreeBSD 12
-------------------------

To build Gnustep under Feebsd

Here is how to get such a installation up and running under FreeBSD 12 (codename Stretch)


First we need some basic tools and repository's set up


1. Depenencies
--------------------------

pkg install git \
	autoconf \
	automake \
	cmake \
	subversion  \
	wget \
	bash \
	pkgconf \
	sudo \
	gmake \
	windowmaker \
	jpeg \
	tiff \
	png \
	libxml2 \
	libxslt \
	gnutls \
	libffi \
	icu \
	cairo \
	avahi \
	portaudio \
	flite \
	pngwriter \
	mariadb103-client \
	postgresql96-client \
	bash


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

export CC="clang-devel"
export CXX="clang++-devel"
export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"
#export RUNTIME_VERSION="gnustep-2.0"
#export CPPFLAGS="-L/usr/local/lib -L${PREFIX}/lib"
#export LD="/usr/bin/lld-7"
#export LDFLAGS="-fuse-ld=${LD}"
#export OBJCFLAGS="-fblocks"
#export CFLAGS="-I ${PREFIX}/include"

#mkdir -p ${PREFIX}/lib
#mkdir -p ${PREFIX}/etc
#mkdir -p ${PREFIX}/bin

#    cd swift-corelibs-libdispatch
#    mkdir build
#    cd build
#    cmake .. -DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX} -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=${PREFIX}
#    make
#    make install
    

    

5. install libobjc2 runtime

    cd libobjc2
    mkdir Build
    cd Build
    cmake ..  -DCMAKE_BUILD_TYPE=Release -DBUILD_STATIC_LIBOBJC=1  -DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX}
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
gmake
gmake install
source /etc/GNUstep/GNUstep.conf
cd ..
 
7. install gnustep-base


cd base
./configure --with-config-file=/etc/GNUstep/GNUstep.conf


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
    


