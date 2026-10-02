#!/bin/bash


if [ "$UID" -eq 0 ]
then
	SUDOE=
	SUDOL=
else
	SUDOE="sudo -E"
	SUDOL="sudo"
	LDCONFIG="/sbin/ldconfig"
fi

function print_title()
{
	printf "\n \033[22;33m=== $1 ===\033[0m \n\n"
}

function print_alert()
{
	printf "\n \033[22;31m=== Alert! ===\033[0m \n"
	printf "\033[22;31m [E] ${1} \033[0m \n\n"
}

function print_warning()
{
	printf "\n \033[22;35m=== Warning! ===\033[0m \n"
	printf "\033[22;35m /!\ ${1} \033[0m \n\n"
}

function print_info()
{
	printf "\n \033[22;36m=== Info ===\033[0m \n"
	printf "\033[22;36m (i) ${1} \033[0m \n\n"
}

function print_cli()
{
	printf "\n\t\033[22;36m ${1} \033[0m \n\n"
}

function print_ok()
{
	printf "\033[22;32m${1}\033[0m.\n"
}

function install_cmake
{	
	SECTION=$1
	LOG=`pwd`/$2
	DIR=$3

	TITLE="Buildling and installing ${SECTION}..."
	echo "$TITLE" >$LOG
	print_title "$TITLE"
	
	TITLE="Building ${SECTION}..."
	echo "$TITLE" >>$LOG
	printf "$TITLE\n"
	
	cd "${DIR}" || exit -1

	printf "\nconfiguring "
	./configure  &>>$LOG &
	spinner $!
	
	printf "\ncompiling "
    make -j8 &>>$LOG &
   	spinner $!
	print_ok "\ndone"

	printf "installing "
    sudo -E make -j8 install &>>$LOG &
   	spinner $!
	print_ok "\ndone"
    cd ..
    CMAKE=/usr/local/bin/cmake
}
#############################################
# spinner
#############################################
# call it like this:
# set up some task and put it into the background
# sometask &
# spinner $!


function spinner
{
	AWAIT_PID=$1
	SPIN='/-\|'
	i=1
	echo -n ' '
	while [ -d /proc/$AWAIT_PID ]
	do
		sleep 0.2
		printf "\b${SPIN:i++%${#SPIN}:1}"
	done
}

#syntax:   check_install <section> <logfile> <dir> <url>

function check_install 
{
	SECTION="$1"
	LOG=`pwd`/"$2"
	DIR="$3"
	URL="$4"
	TITLE="Checking ${SECTION} installation..."
	print_title "${TITLE}"
	local _COUNT=0

	grep -e " Error " $LOG &>/dev/null
	if [ $? -eq 0 ]
	then
		_COUNT=$(( $_COUNT + 1 ))
	fi
	grep -v " error: nil" $LOG | grep -e " error: " &>/dev/null
	if [ $? -eq 0 ]
	then
		_COUNT=$(( $_COUNT + 1 ))
	fi
	
	if [ ${_COUNT} -ne 0 ]
	then
		print_alert "$NAME installation has generated ${_COUNT} errors: check the log $LOG"
		exit 1
	else
		print_info "$NAME installation was successful. You can go forward."
		sleep 5
	fi
}

#syntax:   fetch_tgz_generic <section> <logfile> <directory> <url> option
function fetch_tgz_generic
{
	SECTION=$1
	LOG=$2
	DIR=$3
	URL=$4
	echo fetch_tgz_generic $1 $2 $3 $4
	OPTIONS="--no-clobber $5"
	print_ok "\rFetching $1"
	if [ -d "${DIR}" ]
	then
		TITLE=" already downloaded ${SECTION}"
		echo "$TITLE" >> $LOG
		printf "$TITLE\n"
	else
		TITLE=" downloading $SECTION using curl from $URL"
		echo "$TITLE" >> $LOG
		printf "$TITLE\n"
    	curl "${URL}" -L -o ${DIR}.tar.gz $OPTIONS &>>$LOG &
		spinner $!
		printf "\n extracting ${SECTION}\n"
		echo "tar -xvzf ${DIR}.tar.gz"
		tar -xvzf ${DIR}.tar.gz &>>$LOG &
		spinner $!
	fi	
	print_ok "\rDone"
}

function fetch_git_generic
{
	SECTION=$1
	LOG=$2
	DIR=$3
	URL=$4
	print_ok "\rFetching $1"
	if [ -d "${DIR}" ]
	then
		TITLE=" updating ${SECTION}..."
		echo "$TITLE" >> $LOG
		printf "$TITLE\n"
		cd "${DIR}"
		git pull &>>$LOG &
		spinner $!
		cd ..
	else
		TITLE=" downloading ${SECTION} using git from ${URL}"
		echo "$TITLE" >> $LOG
		printf "$TITLE\n"
		git clone $URL &>>$LOG &
		spinner $!
	fi
	print_ok "\rDone"
}


#syntax fetch_sources <section> <logfile>
function fetch_sources()
{
	SECTION="$1"
	LOG=`pwd`/"$2"
	TITLE="Checking out Sources..."
	echo "$TITLE" >> $LOG
	print_title "$TITLE\n"

	if [ "${NEED_CMAKE}" == "1" ]
	then
		fetch_tgz_generic       cmake					$LOG	cmake-4.2.0					https://github.com/Kitware/CMake/releases/download/v4.2.0/cmake-4.2.0.tar.gz
	fi
	fetch_tgz_generic       libiconv				$LOG	libiconv-1.18				http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.18.tar.gz "-4"
	fetch_git_generic 		libobjc2 				$LOG 	libobjc2  					https://github.com/gnustep/libobjc2
	fetch_git_generic 		libdispatch				$LOG 	swift-corelibs-libdispatch	https://github.com/apple/swift-corelibs-libdispatch
	fetch_git_generic		gnustep-scripts 		$LOG 	scripts						https://github.com/gnustep/scripts
	fetch_git_generic		gnustep-make    		$LOG 	make						https://github.com/gnustep/make
	fetch_git_generic		gnustep-base    		$LOG 	base						https://github.com/gnustep/base
	fetch_git_generic		gnustep-corebase		$LOG 	corebase					https://github.com/gnustep/corebase
	fetch_git_generic		gnustep-gui    			$LOG 	gui							https://github.com/gnustep/gui
	fetch_git_generic		gnustep-back    		$LOG 	back						https://github.com/gnustep/back
}

function install_libiconv
{
	SECTION=$1
	LOG=`pwd`/$2
	DIR=$3
	URL=$4

	echo "libiconv: I am in directory `pwd`"

	TITLE="Buildling and installing ${SECTION}..."
	echo "$TITLE" >$LOG
	print_title "$TITLE"
	
	TITLE="Building ${SECTION}..."
	echo "$TITLE" >>$LOG
	printf "$TITLE\n"
	
	cd "${DIR}" || exit -1
	
	
	printf "\nconfiguring "

	CC=gcc CXX="gcc++" CFLAGS="-fPIC" CPPFLAGS="-fPIC" ./configure --enable-static --enable-dynamic &>>$LOG &
	spinner $!
	
	printf "\ncompiling "
    make -j8 &>>$LOG &
   	spinner $!
	print_ok "\ndone"

	printf "installing "
    sudo -E make -j8 install &>>$LOG &
   	spinner $!
    ./libtool --finish /usr/local/lib  &>>$LOG &
   	spinner $!
	print_ok "\ndone"
    cd ..
	sudo /sbin/ldconfig
}

function install_libdispatch
{
	SECTION=$1
	LOG=`pwd`/$2
	DIR=$3
	URL=$4
	
	TITLE="Buildling and installing ${SECTION}..."
	echo "$TITLE" >$LOG
	print_title "$TITLE"
	
	cd "${DIR}" || exit 1
	if [ -d build ]
	then
	    rm -rf build
	fi
    mkdir -p build
    cd build

   	printf "\n configuring..."
	${CMAKE}  -DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX} -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/usr .. &>>$LOG &
   	spinner $!
   	printf "\n building..."

    make -j8 &>>$LOG &
   	spinner $!
   	printf "\n installing..."

    sudo -E make -j8 install  &>>$LOG &
   	spinner $!
   	print_ok "\nInstalled!"
	sudo /sbin/ldconfig
	cd ../..
}

function install_libobjc2
{
	SECTION=$1
	LOG=`pwd`/$2
	DIR=$3
	URL=$4
		
	TITLE="Buildling and installing ${SECTION}..."
	echo "$TITLE" >$LOG
	print_title "$TITLE"
	
	
	pushd $DIR > /dev/null
	if [ -d build ]
	then
	    rm -rf build
	fi
    mkdir -p build
    cd build

   	printf "\n configuring..."
    ${CMAKE}  .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_STATIC_LIBOBJC=1  -DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX} -DCMAKE_INSTALL_PREFIX=/usr &>>$LOG &
   	spinner $!

   	printf "\n building..."
   	make -j8 &>>$LOG &
   	spinner $!

   	printf "\n installing..."
   	sudo -E make -j8 install  &>>$LOG &
   	spinner $!
   	print_ok "\nInstalled!"
	sudo /sbin/ldconfig

	popd > /dev/null
}


function settingup_environment
{
	export CC="/usr/bin/clang"
	export CXX="/usr/bin/clang++"
	export PREFIX="/"
	export PATH="/usr/GNUstep/System/Tools:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"
	export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
	export RUNTIME_VERSION="gnustep-2.0"
	export OBJCFLAGS="-fblocks"
	export CFLAGS="-I ${PREFIX}/include"
	export GNUSTEP_INSTALLATION_DOMAIN="SYSTEM"
}

function settingup_environment_part2
{
	export PATH="/usr/GNUstep/System/Tools:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"
	export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
}

#syntax:   install_gnustep_make <section> <logfile>
function install_gnustep_make
{
	SECTION=$1
	LOG=`pwd`/$2
	DIR=$3
	URL=$4
		
	TITLE="Buildling and installing ${SECTION}..."
	echo "$TITLE" >$LOG
	print_title "$TITLE"
	
	pushd $DIR > /dev/null

	sudo -E make distclean &>/dev/null
   	printf "\n configuring..."
	./configure \
        --with-layout=fhs-system \
        --disable-importing-config-file \
        --enable-native-objc-exceptions \
        --enable-objc-arc \
        --enable-install-ld-so-conf \
        --with-library-combo=ng-gnu-gnu \
        --with-config-file=/etc/GNUstep/GNUstep.conf \
        --with-user-config-file='.GNUstep.conf' \
        --with-user-defaults-dir='GNUstep/Library/Defaults' \
        --with-objc-lib-flag="-l:libobjc.so.4.6" &>>$LOG &
        

	spinner $!
   	printf "\n building..."
	make -j8 &>>$LOG &
	spinner $!

   	printf "\n installing..."
	sudo -E make install &>>$LOG &
	spinner $!
	print_ok "\rDone"
	sudo /sbin/ldconfig
	popd > /dev/null
}

#syntax:   install_gnustep_base <section> <logfile>
function install_gnustep_base 
{
	SECTION=$1
	LOG=`pwd`/$2
	DIR=$3
	URL=$4

	source /etc/GNUstep/GNUstep.conf	
	TITLE="Buildling and installing ${SECTION}..."
	echo "$TITLE" > $LOG
	print_title "$TITLE"
	pushd $DIR > /dev/null
	sudo -E make distclean &>/dev/null
	printf "Configuring...\n"
	./configure \
	    --disable-importing-config-file \
		--with-config-file=/etc/GNUstep/GNUstep.conf \
        --with-libiconv-include=/usr/local/include \
        --with-libiconv-library=/usr/local/lib \
        --enable-pass-arguments \
        --enable-zeroconf \
        --enable-icu \
        --enable-libdispatch \
        --enable-nsurlsession \
        --with-installation-domain=SYSTEM &>>$LOG &
	spinner $!
	printf "\rBuilding...\n"
	make -j8 &>>$LOG &
	spinner $!
	printf "\rInstalling...\n"
	sudo -E make install &>>$LOG &
	spinner $!
	print_ok "\rDone"
	sudo /sbin/ldconfig
	popd
}

#syntax:   install_gnustep_base <section> <logfile>
function install_gnustep_corebase 
{
	SECTION=$1
	LOG=`pwd`/$2
	DIR=$3
	URL=$4
	
	TITLE="Buildling and installing ${SECTION}..."
	echo "$TITLE" >$LOG
	print_title "$TITLE"
	pushd $DIR > /dev/null
	sudo -E make distclean &>/dev/null
	printf "Configuring...\n"
	./configure &>>$LOG &
	spinner $!
	printf "\rBuilding...\n"
	make -j8 &>>$LOG &
	spinner $!
	printf "\rInstalling...\n"
	sudo -E make install &>>$LOG &
	spinner $!
	print_ok "\rDone"
	sudo /sbin/ldconfig
	popd > /dev/null
}

#syntax:   install_gnustep_gui <section> <logfile>
function install_gnustep_gui
{
	SECTION=$1
	LOG=`pwd`/$2
	DIR=$3
	URL=$4
	
	TITLE="Buildling and installing ${SECTION}..."
	echo "$TITLE" >$LOG
	print_title "$TITLE"
	pushd $DIR > /dev/null
	sudo -E make distclean &>/dev/null
	mv configure.ac configure.ac.bck
	cat configure.ac.bck | sed 's/^AC_CONFIG_AUX_DIR/#AC_CONFIG_AUX_DIR/g' > configure.ac
	/usr/GNUstep/System/Library/Makefiles/config.guess .
	/usr/GNUstep/System/Library/Makefiles/config.sub .
	autoreconf -vif
	autoconf
	
	printf "Configuring...\n"
	export LIBS="-lao"
       	./configure &>>$LOG &
	spinner $!
	printf "\rBuilding...\n"
	make -j8 &>>$LOG &
	spinner $!
	printf "\rInstalling...\n"
	sudo -E make install &>>$LOG &
	spinner $!
	print_ok "\rDone"
	sudo /sbin/ldconfig
	popd > /dev/null
}

#syntax:   install_gnustep_back name <section> <logfile>
function install_gnustep_back
{
	SECTION=$1
	LOG=`pwd`/$2
	DIR=$3
	URL=$4
	
	TITLE="Buildling and installing ${SECTION}..."
	echo "$TITLE" >$LOG
	print_title "$TITLE"
	pushd $DIR > /dev/null
	sudo -E make distclean &>/dev/null
	
	mv configure.ac configure.ac.bck
	cat configure.ac.bck | sed 's/^AC_CONFIG_AUX_DIR/#AC_CONFIG_AUX_DIR/g' > configure.ac
	/usr/GNUstep/System/Library/Makefiles/config.guess .
	/usr/GNUstep/System/Library/Makefiles/config.sub .
	autoupdate
	autoreconf -vif
	autoconf

	printf "Configuring...\n"
	./configure &>>$LOG &
	spinner $!
	printf "\rBuilding...\n"
	make -j8 &>>$LOG &
	spinner $!
	printf "\rInstalling...\n"
	sudo -E make install &>>$LOG &
	spinner $!
	print_ok "\rDone"
	sudo /sbin/ldconfig
	popd > /dev/null
}

#syntax:   install_dependencies <section> <logfile>

function install_dependencies
{
	SECTION=$1
	LOG=`pwd`/$2
	TITLE="Installing dependencies..."
	echo "$TITLE" >>$LOG
	print_title "$TITLE"

	for PKG in build-essential git subversion  \
        clang lldb robin-map-dev\
        libxml2 libxml2-dev \
        libffi8 libffi-dev\
        libicu76 libicu-dev \
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
        libfreetype6 libfreetype-dev \
        libcairo2-dev \
        libxt-dev \
        libgl1-mesa-dev \
        libpcap-dev \
        python3-dev swig \
        libedit-dev readline-common \
        binfmt-support libncurses-dev \
        bison flex m4 wget \
        libicns1    libicns-dev \
        libxslt1.1  libxslt1-dev \
        libxft2 libxft-dev \
        libflite1 flite1-dev \
        libxmu6 libxpm4 wmaker-common\
        libgnutls30t64 libgnutls28-dev gnutls-bin\
        libpng-dev libpng16-16t64\
        libreadline8t64 libreadline-dev \
        libgif7 libgif-dev libwings3 libwings-dev  libwutil5 \
        libcups2-dev \
        xorg \
        libpango1.0-dev \
        libxt-dev libssl-dev \
        libasound2-dev libjack-dev libjack0 libportaudio2 libportaudiocpp0 portaudio19-dev \
        wmaker cmake cmake-curses-gui \
        libwraster6 libwraster-dev \
        ninja-build \
        gobjc gobjc-12 \
        gobjc++ gobjc++-12 \
        default-libmysqlclient-dev \
        libpq-dev libpq5 curl libcurl4-openssl-dev \
        libzmq3-dev libzmq5 libmariadb-dev \
        libavahi-core-dev libavahi-core7 libsctp-dev libsctp1 libpcap-dev \
        bison flex 
    do	
    	echo $PKG
		sudo apt-get install $PKG &>>$LOG &
		spinner $!
	done 
    ./scripts/install-dependencies-linux
}

echo "removing old gnustep"
apt-get purge libblocksruntime-dev
apt-get purge gnustep-base
apt-get purge gnustep-gui

mkdir -p gnustep_build
cd gnustep_build

NEED_CMAKE=0
CMAKE=cmake
DEBVER=`cat /etc/debian_version | cut -f1 -d.`
if [ "${DEBVER}" -lt 13 ]
then
	NEED_CMAKE=1
	CMAKE=/usr/local/bin/cmake
fi

fetch_sources				download-sources	fetch-sources.log
install_dependencies		dependencies		install-dependencies.log

if [ "${NEED_CMAKE}" == "1" ]
then
	install_cmake 	cmake	build-cmake.log	cmake-4.2.0	
	check_install 	cmake	build-cmake.log	cmake-4.2.0	
fi

install_libiconv    		libiconv			build-libiconv.log				libiconv-1.18				http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.18.tar.gz
check_install	    		libiconv			build-libiconv.log				libiconv-1.18				http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.18.tar.gz

settingup_environment

install_libobjc2			libobjc2 			build-libobjc2.log			 	libobjc2  					https://github.com/gnustep/libobjc2
check_install				libobjc2 			build-libobjc2.log	 			libobjc2  					https://github.com/gnustep/libobjc2
install_libdispatch			libdispatch			build-libdispatch.log		 	swift-corelibs-libdispatch	https://github.com/apple/swift-corelibs-libdispatch
check_install				libdispatch			build-libdispatch.log			swift-corelibs-libdispatch	https://github.com/apple/swift-corelibs-libdispatch
install_gnustep_make		gnustep-make    	build-gnustep-make.log		 	make						https://github.com/gnustep/make
check_install				gnustep-make    	build-gnustep-make.log			make						https://github.com/gnustep/make

source /etc/GNUstep/GNUstep.conf

install_gnustep_base		gnustep-base    	build-gnustep-base.log  		base						https://github.com/gnustep/base
check_install				gnustep-base    	build-gnustep-base.log  		base						https://github.com/gnustep/base
install_gnustep_corebase	gnustep-corebase	build-gnustep-corebase.log  	corebase					https://github.com/gnustep/corebase
check_install				gnustep-corebase	build-gnustep-corebase.log 		corebase					https://github.com/gnustep/corebase
install_gnustep_gui			gnustep-gui    		build-gnustep-gui.log 			gui							https://github.com/gnustep/gui
check_install				gnustep-gui    		build-gnustep-gui.log 			gui							https://github.com/gnustep/gui
install_gnustep_back		gnustep-back    	build-gnustep-back.log 			back						https://github.com/gnustep/back
check_install				gnustep-back    	build-gnustep-back.log 			back						https://github.com/gnustep/back

#install_gworkspace			gworkspace	    	build-gworkspace.log 			apps-gworkspace				https://github.com/gnustep/apps-gworkspace
#check_install				gworkspace    		build-gworkspace.log 			apps-gworkspace				https://github.com/gnustep/back
	
