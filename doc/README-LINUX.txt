ulib under Linux
----------------

To user ulib with Linux you need to build your own gnustep installation
The ones shipped with the distributions is not supporting automatic 
reference counting because its using the old objc runtime.

Here is how to get such a installation up and running under the following 
distributions

	Debian 8 (i386)
	Debian 8 (amd64)
	Debian 8 (armhf) / Raspbian
	Ubuntu 14.04.5 LTS (i386)
	Ubuntu 14.04.5 LTS (amd64)
	Ubuntu 16.04.1 LTS (i386)
	Ubuntu 16.04.1 LTS (amd64)
	Centos 6 (i386)
	Centos 6 (amd64)
	Centos 7 (amd64)

1. Install depenencies
--------------------------

  Debian & Ubuntu & Raspbian
  --------------------------

  apt-get install build-essential \
        libkqueue0 libkqueue-dev  \
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
        libgnutls-deb0-28 libgnutls28-dev \
        libgcrypt20 libgcrypt20-dev \
        libtiff5 libtiff5-dev \
        libssl1.0.0 libssl-dev \
        libbsd0 libbsd-dev \
        util-linux-locales \
        libjpeg-dev \
        libtiff-dev  \
        libpng12-dev  \
        libcups2-dev  \
        libfreetype6-dev \
        libcairo2-dev \
        libxt-dev \
        libgl1-mesa-dev \
        libpcap-dev \
        libstdc++-4.8-dev \
        libc-dev libc++-dev \
        python-dev swig \
        libedit-dev libeditline0  libeditline-dev libreadline6 libreadline6-dev readline-common \
        binfmt-support libtinfo-dev \
        bison flex m4 wget

now install the latest clang-5.0
        wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key > /tmp/llvm-snapshot.gpg.key
        apt-key add /tmp/llvm-snapshot.gpg.key
        apt-get update
        apt-get install clang-5.0 llvm-5.0 lldb-5.0
        cd /usr/bin/
        for BINARY in  bugpoint c-index-test clang clang++ clang-apply-replacements clang-change-namespace clang-check clang-cl clang-cpp clang-import-test clang-include-fixer clang-offload-bundler clang-query clang-rename clang-reorder-fields clang-tblgen find-all-symbols llc lldb lldb-5.0.0 lldb-argdumper lldb-mi lldb-mi-5.0.0 lldb-server lldb-server-5.0.0 lli lli-child-target llvm-ar llvm-as llvm-bcanalyzer llvm-cat llvm-config llvm-cov llvm-c-test llvm-cxxdump llvm-cxxfilt llvm-diff llvm-dis llvm-dsymutil llvm-dwarfdump llvm-dwp llvm-extract llvm-lib llvm-link llvm-lto2 llvm-lto llvm-mc llvm-mcmarkup llvm-modextract llvm-nm llvm-objdump llvm-opt-report llvm-pdbdump llvm-PerfectShuffle llvm-profdata llvm-ranlib llvm-readobj llvm-rtdyld llvm-size llvm-split llvm-stress llvm-strings llvm-symbolizer llvm-tblgen llvm-xray modularize obj2yaml opt sancov sanstats scan-build scan-view verify-uselistorder yaml2obj yaml-bench
        do
            if [ -L "$BINARY" ]
            then
                if [ -L "$BINARY-5.0" ]
                then
                    rm "$BINARY"
                    ln -s "$BINARY-5.0" "$BINARY"
                fi
            fi
         done
         
         export CC=clang
         export CXX=clang++
         

  Debian8 only:			apt-get install libgnutls-deb0-28  libcups2-dev  locales-all libicu52
  Ubuntu14 only:		apt-get install locales libicu52
  Ubuntu16 only:		apt-get install locales libicu55
  
    Centos6 / Redhat Enterprise Server 6
    ------------------------------------
    yum groupinstall "Development tools" "Debugging Tools"
    yum install \
        lksctp-tools lksctp-tools-devel \
        libxml2 libxml2-devel \
        libffi libffi-devel \
        icu libicu libicu-devel \
        libbsd libbsd-devel
        uuid uuid-devel \
        avahi avahi-devel avahi-libs avahi-ui-devel \
        gnutls gnutls-devel \
        libgcrypt libgcrypt-devel \
        libtiff libtiff-devel \
        openssl openssl-devel \
        libjpeg libjpeg-dev \
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
        cmake3


manual compile and install on centos:

  First we need some newer version of the autotools

    wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz
    cd autoconf-2.69
    ./configure
    make
    make install
    cd ..
    
    wget http://ftp.gnu.org/gnu/automake/automake-1.15.tar.gz
    cd automake-1.15
    ./configure
    make
    make install
    cd ..
    
    wget http://ftp.gnu.org/gnu/libtool/libtool-2.4.6.tar.gz
    cd libtool-2.4.6
    ./configure
    make
    make install
    cd ..

    wget https://pkg-config.freedesktop.org/releases/pkg-config-0.29.1.tar.gz
    
  Secondly we need libdispatch which in turn needs libkqueue and libpthread-workqueue
  
    blocks-runtime
        git clone https://github.com/mheily/blocks-runtime.git
        cd blocks-runtime
        autoreconf --install
        ./configure
        make
        make install
        cd ..

    libkqueue:
        download libkqueue from  https://sourceforge.net/projects/libkqueue/
        a simple configure/make/make install run will do
    
    libpthread-workqueue
        git clone https://github.com/mheily/libpwq.git
        cd libpwq
        autoreconf --install
        ./configure
        make
        make install
        
    We will also need libblocksruntime but we cant compile it just yet due to missing clang
        https://github.com/mheily/blocks-runtime.git
        https://github.com/nickhutchinson/libdispatch


2a. Add the clang/llvm repositories and install a recent version of clang
-------------------------------------------------------------------------
(for Debian/Ubunut)
2a.1: create a file /etc/apt/sources.list.d/llvm.list with the following content

    deb http://llvm.org/apt/jessie/ llvm-toolchain-jessie main
    deb-src http://llvm.org/apt/jessie/ llvm-toolchain-jessie main

this links in the latest LLVM compiler version.
(Somewhere around version 3.5 is the minimum, I tested with clang version 4.0.0-svn285499-1~exp1)


. Import the key from the keyserver and update your repository index.
(run it with sudo in front if you are not root)

    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 15CF4D18AF4F7421
    apt-get update


2a.2: Install the clang compiler and the lldb debugger in version 4.0 

    apt-get -y install build-essential git llvm-4.0 clang-4.0 lldb-4.0 libclang-4.0-dev

2a.3: link the "clang" and "clang++" names to the latest 4.0 version

    pushd /usr/bin
    for F in pp-trace scan-build scan-view clang clang++ clang-tidy clang-tblgen clang-query clang-check clang-apply-replacements c-index-test lldb
    do
        rm $F
        ln -s $F-4.0 $F
    done
    popd
    
    pushd /usr/lib
    ln -s llvm-4.0 llvm
    popd
    
    pushd /usr/share
    ln -s llvm-4.0 llvm
    popd
    
    

2b: For CentOS 6, we have to compile clang.
-------------------------------------------

for CentOS 6 you need to compile gcc 5.4.0 first to then compile the llvm and clang 3.6.2 source to get a working clang compiler.
for Centos 7, compiling clang 3.6.3 is enough.
Note: you need to use "cmake3" wherever it says "cmake"
And you might want to check your PATH variable as /usr/local/bin might not be in it.


3. Download the sourcecode of gnustep and libobjc2 and cmake

    wget ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-make-2.6.8.tar.gz
    wget ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-base-1.24.9.tar.gz
    wget ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-gui-0.25.0.tar.gz
    wget ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-back-0.25.0.tar.gz
    wget ftp://ftp.gnustep.org/pub/gnustep/libs/gnustep-corebase-0.1.tar.gz
    wget http://download.gna.org/gnustep/libobjc2-1.7.tar.bz2

4. Setup your gnustep-make (small inital config to bootstrap libobj2)

    tar -xvzf gnustep-make-2.6.8.tar.gz
    cd gnustep-make-2.6.8
    CC=clang CXX=clang++  ./configure --enable-objc-arc -enable-objc-nonfragile-abi
    make install
    cd ..


5. Prepare libobjc2

   tar -xvjf libobjc2-1.7.tar.bz2
   cd libobjc2-1.7
    mkdir Build
    cd Build
    cmake .. -DBUILD_STATIC_LIBOBJC=1  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ 
    make install
    cd ../..


	if cmake spills out some errors try ediit the file opts/CMakeLists.txt and comment out the following lines

    #find_package(LLVM)
    #include(AddLLVM)
    ...
    #add_llvm_loadable_module( libGNUObjCRuntime
    #  ClassIMPCache.cpp
    #  ClassMethodInliner.cpp
    #  IvarPass.cpp
    #  ObjectiveCOpts.cpp
    #  TypeFeedbackDrivenInliner.cpp
    #  ClassLookupCache.cpp
    #  IMPCacher.cpp
    #  LoopIMPCachePass.cpp
    #  TypeFeedback.cpp
    #)
   
	now you can continue building

(you can add -DCMAKE_BUILD_TYPE=Debug but this will drastically increase build time and binary sizes.
And if you installed a clang compiler yourself, make sure the path is set to find it or modify the -DCMAKE_C_COMPILER / -DCMAKE_CXX_COMPILER options accordingly.


--enable-objc-arc --enable-objc-nonfragile-abi 

6. gnustep-make, part 2 (full config)

    cd gnustep-make-2.6.8
    ./configure \
        CC=clang \
        CXX=clang++ \
        CFLAGS=-fobjc-arc \
        --disable-importing-config-file \
        --enable-objc-nonfragile-abi \
        --enable-objc-arc \
        --with-layout=fhs 
    make install
    cd ..

10. gnustep-base

    tar -xvzf gnustep-base-1.24.9.tar.gz
    cd gnustep-base-1.24.9
    ./configure \
        CC=clang \
        CXX=clang++ \
        CFLAGS="-fblocks  -fobjc-runtime=gnustep -DEXPOSE_classname_IVARS=1"\
        --with-zeroconf-api=avahi
    make
    make install
    ldconfig
    cd ..

(for debug version use "make debug=yes" instead of "make")
If it fails telling you that objc/objc.h is present but can not be compiled, check for the header /usr/include/unistd.h and replace __block in it with __xblock as __block is now a reserved word)
On centos6 you also need to get a newer version of libiuc from http://download.icu-project.org/files/icu4j/58.2/icu4j-58_2.tgz and compile it

11. gnustep-corebase-0.1

    tar -xvzf gnustep-corebase-0.1.tar.gz
    cd gnustep-corebase-0.1
    ./configure \
        CC=clang \
        CXX=clang++ \
        CFLAGS="-fblocks -fobjc-runtime=gnustep -DEXPOSE_classname_IVARS=1"\
        LD=gcc
    make
    make install
    ldconfig
    cd ..

12. ulib
    git clone http://github.com/andreasfink/ulib
    cd ulib
    ./configure
    make
    make install
    ldconfig
    cd ..

13. webserver sample application
    git clone http://github.com/andreasfink/webserver
    cd webserver
    ./configure
    make
    make install
    
14. If you want X11 GUI support in GnuStep

    apt-get install \
        Xorg \
        libfreetype6 libfreetype6-dev \
        libpango1.0-dev \
        libcairo2-dev \
        libxt-dev \
        libcups2-dev

14.  gnustep-gui

    tar -xvzf gnustep-gui-0.25.0.tar.gz
    cd gnustep-gui-0.25.0
    ./configure \
        CC=clang \
        CXX=clang++ \
        CFLAGS="-fblocks -fobjc-runtime=gnustep -DEXPOSE_classname_IVARS=1" \
        LD=gcc
    make
    make install
    cd ..


15. gnustep-back

    tar -xvzf gnustep-back-0.25.0.tar.gz
    cd gnustep-back-0.25.0
    ./configure CC=clang CXX=clang++ CFLAGS="-fblocks \
        -fobjc-runtime=gnustep -DEXPOSE_classname_IVARS=1" LD=gcc
    make
    make install
    cd ..


16. For universalSS7 the following dependency is also needed

	wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
	tar -xvzf libiconv-1.14.tar.gz
	cd libiconv-1.14
	./configure
	make
	make install
	cd ..
	
	
