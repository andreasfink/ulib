Gnustep under FreeBSD 15
-------------------------

The GNUStep version which comes with FreeBSD 15.1 is already compiled with libobjc2 support
so no longer needed to compile it by hand. umscript uses gnustep-corebase which in turn
uses  grand central dispatch so its advisable to install these.


Download the sourcecode of gnustep and dependencies
---------------------------------------------------

    mkdir gnustep
    cd gnustep
    git clone https://github.com/apple/swift-corelibs-libdispatch
    git clone https://github.com/gnustep/corebase


Setting some defaults
------------------------------------------------
Especially make sure our PKG_CONFIG_PATH environment variable finds gnustep-config


export PS1='[\u@'`hostname`' \W]\$ '
export SVN_EDITOR=vi
export EDITOR=vi
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export XTERM_LOCALE=en_US.UTF-8
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
export CC=/usr/bin/clang
export CXX=/usr/bin/clang++
export PATH=/opt/buildtools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin/bin
export RUNTIME_VERSION=gnustep-2.1
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/usr/local/libdata/pkgconfig:/usr/libdata/pkgconfig:/usr/lib32/pkgconfig
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/usr/local/libdata/pkgconfig/:/usr/libdata/pkgconfig

export CC="clang"
export CXX="clang++"
export PATH="/opt/buildtools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:/usr/bin:/bin:
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"
export RUNTIME_VERSION="gnustep-2.1"
export LDFLAGS="-L/usr/local/lib"

#export LD="/usr/local/bin/mold"
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


    ./configure  --with-config-file=/usr/local/GNUstep/GNUstep.conf
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



