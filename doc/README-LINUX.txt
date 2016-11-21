ulib under Linux
----------------

To user ulib with Linux you need to build your own gnustep installation
The ones shipped with the distributions is not supporting automatic 
reference counting because its using the old objc runtime.

Here is how to get such a installation up and running under Debian 8


1. Add the clang/llvm repositories
---------------------------------------

1. create a file /etc/apt/sources.list.d/llvm.list with the following content

    deb http://llvm.org/apt/jessie/ llvm-toolchain-jessie main
    deb-src http://llvm.org/apt/jessie/ llvm-toolchain-jessie main

this links in the latest LLVM compiler version.
(Somewhere around version 3.5 is the minimum, I tested with clang version 4.0.0-svn285499-1~exp1)


2. Import the key from the keyserver and update your repository index.
(run it with sudo in front if you are not root)

    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 15CF4D18AF4F7421
    apt-get update


3. Install the clang compiler and the lldb debugger in version 4.0 

    apt-get -y install build-essential git llvm-4.0 clang-4.0 lldb-4.0 libclang-4.0-dev

4. link the "clang" and "clang++" names to the latest 4.0 version

    pushd /usr/bin
    for F in pp-trace scan-build scan-view clang clang++ clang-tidy clang-tblgen clang-query clang-check clang-apply-replacements c-index-test
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


5. Install dependencies for gnustep and ulib
    apt-get install  \
        libkqueue0 libkqueue-dev  \
        libpthread-workqueue0 libpthread-workqueue-dev \
        libblocksruntime0 libblocksruntime-dev \
        libxml2 libxml2-dev \
        libffi6 libffi-dev\
        libicu52 libicu-dev \
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
        locales-all \
        util-linux-locales \
        libxml2-dev  \
        libjpeg-dev \
        libtiff-dev  \
        libpng12-dev  \
        libcups2-dev  \
        libfreetype6-dev \
        libcairo2-dev \
        libxt-dev \
        libgl1-mesa-dev \
        gobjc

6. Download the sourcecode of gnustep and libobjc2 and cmake

    wget ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-make-2.6.8.tar.gz
    wget ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-base-1.24.9.tar.gz
    wget ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-gui-0.25.0.tar.gz
    wget ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-back-0.25.0.tar.gz
    wget ftp://ftp.gnustep.org/pub/gnustep/libs/gnustep-corebase-0.1.tar.gz
    wget http://download.gna.org/gnustep/libobjc2-1.7.tar.bz2
    wget https://cmake.org/files/v3.7/cmake-3.7.0.tar.gz


7. install cmake-3.7  (version 3.0.2 which gets installed with debian gives you some scripting error with llvm)

    tar -xvzf cmake-3.7.0.tar.gz
    cd /cmake-3.7.0.
    CC=clang CXX=clang++ ./configure
    make
    make install

6. Setup your gnustep-make (small inital config to bootstrap libobj2)

    tar -xvzf gnustep-make-2.6.8.tar.gz
    cd gnustep-make-2.6.8
    CC=clang CXX=clang++  ./configure --enable-objc-nonfragile-abi
    make install
    cd ..


7. Prepare libobjc2

   tar -xvjf libobjc2-1.7.tar.bz2
   cd libobjc2-1.7
   
now ediit the file opts/CMakeLists.txt and comment out the following lines


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

    mkdir Build
    cd Build
    cmake .. -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++
    make install
    cd ../..

8. gnustep-make, part 2 (full config)

    cd gnustep-make-2.6.8
    ./configure \
        CC=clang \
        CXX=clang++ \
        --disable-importing-config-file \
        --enable-objc-nonfragile-abi \
        --with-layout=fhs
    make install
    cd ..

9. gnustep-base

    tar -xvzf gnustep-base-1.24.9.tar.gz
    cd gnustep-base-1.24.9
    ./configure \
        CC=clang \
        CXX=clang++ \
        CFLAGS="-fblocks -fobjc-runtime=gnustep -DEXPOSE_classname_IVARS=1"\
        --with-layout=fhs \
        --with-zeroconf-api=avahi \
        --enable-objc-nonfragile-abi 
    make
    make install
    cd ..

10. gnustep-corebase-0.1

    tar -xvzf gnustep-corebase-0.1.tar.gz
    cd gnustep-corebase-0.1
    ./configure \
        CC=clang \
        CXX=clang++ \
        CFLAGS="-fblocks -fobjc-runtime=gnustep -DEXPOSE_classname_IVARS=1"\
        LD=gcc
    make
    make install
    cd ..

11. ulib
    git clone http://github.com/andreasfink/ulib
    cd ulib
    ./configure --enable-debug
    make
    make install
    cd ..

12. webserver sample application
    git clone http://github.com/andreasfink/webser
    cd webser
    ./configure --enable-debug
    make
    make install
    
13. If you want X11 GUI support in GnuStep

    apt-get install 
        Xorg \
        libfreetype6 libfreetype6-dev \
        libpango1.0-dev \
        libcairo2-dev \
        libxt-dev \
        libcups2-dev

13.  gnustep-gui

    tar -xvzf gnustep-gui-0.25.0.tar.gz
    cd gnustep-gui-0.25.0
    ./configure \
        CC=clang \
        CXX=clang++ \
        CFLAGS="-fblocks -fobjc-runtime=gnustep -DEXPOSE_classname_IVARS=1"\
        LD=gcc
    make
    make install
    cd ..


13. gnustep-back

    tar -xvzf gnustep-back-0.25.0.tar.gz
    cd gnustep-back-0.25.0
    ./configure CC=clang CXX=clang++ CFLAGS="-fblocks \
        -fobjc-runtime=gnustep -DEXPOSE_classname_IVARS=1" LD=gcc
    make
    make install
    cd ..

