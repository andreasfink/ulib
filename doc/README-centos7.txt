Base: centos7 minimal install
------------------------------------------

yum install \
        lksctp-tools lksctp-tools-devel \
        libxml2 libxml2-devel \
        libffi libffi-devel \
        icu libicu libicu-devel \
        uuid uuid-devel \
        avahi avahi-devel avahi-libs avahi-ui-devel \
        gnutls gnutls-devel \
        libgcrypt libgcrypt-devel \
        libtiff libtiff-devel \
        openssl openssl-devel \
        libjpeg libjpeg-devel \
        libpng libpng-devel \
        cups cups-devel \
        freetype freetype-devel \
        cairo cairo-devel \
        libXt libXt-devel \
        mesa-libGL mesa-libGL-devel \
        libpcap libpcap-devel \
        libstdc++ libstdc++-devel \
        wget git \
        glibc-devel \
        python-dev swig \
        libedit libedit-devel readline-static readline-devel \
        ncurses-devel ncurses-libs ncurses \
        libxslt-devel\
        libXft-devel flite-devel \
        clang  cmake3 gcc-objc gcc-objc++ 

yum install clang


echo "/usr/local/lib" > "/etc/ld.so.conf.d/local.conf"
ldconfig
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"
export CC=clang
export CXX=clang++

download and install libicns
----------------------------

https://sourceforge.net/projects/icns/files/libicns-0.8.1.tar.gz/download --output-file=libicns-0.8.1.tar.gz
tar -xvzf libicns-0.8.1.tar.gz
cd libicns-0.8.1
./configure
make
sudo make install
cd ..


download and install cmake3

wget https://cmake.org/files/v3.7/cmake-3.7.2.tar.gz
tar xvzf cmake-3.7.2.tar.gz
cd cmake-3.7.2
./configure
make
make install
cd ..
