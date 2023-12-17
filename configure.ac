dnl /* ==================================================================== 
dnl  * Project "ulib"
dnl  * Copyright: © 2023 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
dnl  * ====================================================================
dnl  */ 

dnl
dnl configure.in -- main autoconf macro definition file
dnl
dnl Process this file with autoconf to produce a configure script.
dnl

dnl initialization

AC_PREREQ([2.68])
AC_INIT([ulib],[2.0],[andreas@fink.org])
AC_CONFIG_HEADERS([ulib/ulib_config.h])
AC_SUBST(SHELL)
AC_CONFIG_AUX_DIR(.)
AC_SET_TERMINAL_SEQUENCES()

COPYRIGHT="Copyright © 2023 Andreas Fink (andreas@fink.org). All rights reserved."
PROJECT_NAME="ulib"
CONFIG_DEFINE="ULIB_CONFIG"

dnl Check version number.
VERSION=`head -n 1 VERSION`
MAJORVER=`echo $VERSION | cut -f1 -d.`
MINORVER=`echo $VERSION | cut -f2 -d.`
REVISION=`echo $VERSION | cut -f3 -d.`

dnl Set user who runs ./configure
CUSER=`id -un`
AC_SUBST(VERSION)
AC_SUBST(CUSER)

AC_CONFIG_SECTION([Configuring for $PROJECT_NAME version $VERSION])

dnl Checks system type.
AC_CONFIG_SECTION([Running system checks])
AC_CANONICAL_HOST

dnl Apply system specific rules.
dnl Executable extension for systems that need one, i.e. Cygwin
dnl Set the LIBTOOL to be used to create libs
EXE_EXT=""
LIBTOOL="ar rc"
RANLIB="ranlib"
LIBS="-ldl"
LIBRARY_NAME=$PROJECT_NAME
BUILD_DIR=.
DEPENDENT_PKGCONFIGS="openssl"

PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
export PKG_CONFIG_PATH

#
# we prefer clang over gcc
#
if [[ "$CC" == "" ]]
then
	CC=clang
fi
if [[ "$CXX" == "" ]]
then 
	CXX=clang++
fi
	
case "$host" in
  *apple-darwin*) 
    #
    # MacOS X
    # lets try to find the newest installed SDK for compilation
    # so we know how to link against it
    # the standard location /usr/include and /usr/lib are not good enough
    # it wouldnt build i386 architecture on a ppc system
    #
    UR="`uname -r | cut -f1 -d.`"
    DONE=0
    ARCH="-arch x86_64"
    CFLAGS="$CFLAGS  -fobjc-arc -D_REENTRANT=1 -DDARWIN=1 -Iinclude ${ARCH}"
    LDFLAGS="$LDFLAGS -F/Library/Frameworks -framework Foundation -framework Security"
    BUILD_DIR="build/osx"
    SHARED_LIBRARY_EXTENSION="dylib"
    LIBTOOL="libtool -static -o"
    INSTALL_NAME_TOOL="install_name_tool"
    SHARED_FLAGS="-dynamiclib -Wl,-dylib"
    AC_DEFINE(HAVE_COMMONCRYPTO)
    AC_DEFINE(HAVE_OPENSSL)
    LDFLAGS="$LDFLAGS ${ARCH}"
    ;;

  *-linux-*)
	CFLAGS="$CFLAGS -fPIC -DLINUX -D_XOPEN_SOURCE=700 -D_POSIX_SOURCE"
	DEBIAN_VERSION=`cat /etc/debian_version | cut -f1 -d.`
	if [[ "$DEBIAN_VERSION" == "8" ]]
	then
        CFLAGS="$CFLAGS -D_BSD_SOURCE"
    else
        CFLAGS="$CFLAGS -D_DEFAULT_SOURCE"
	fi
	CFLAGS="$CFLAGS  -Wno-trigraphs  -Wno-missing-field-initializers -Wmissing-prototypes -Wno-implicit-atomic-properties"
	CFLAGS="$CFLAGS -Wno-arc-repeated-use-of-weak -Wduplicate-method-match -Wno-missing-braces -Wparentheses -Wswitch -Wunused-function -Wno-unused-label"
	CFLAGS="$CFLAGS -Wno-unused-parameter -Wunused-variable -Wunused-value -Wempty-body -Wuninitialized -Wno-unknown-pragmas -Wno-shadow"
	CFLAGS="$CFLAGS -Wno-four-char-constants -Wno-conversion -Wconstant-conversion -Wint-conversion -Wbool-conversion -Wenum-conversion"
	CFLAGS="$CFLAGS -Wshorten-64-to-32 -Wpointer-sign -Wno-newline-eof -Wno-selector -Wno-strict-selector-match -Wundeclared-selector"
	CFLAGS="$CFLAGS -Wno-deprecated-implementations -Wprotocol -Wdeprecated-declarations -Wno-sign-conversion "
	CFLAGS="${CFLAGS} -fobjc-arc"
	if [[ -x /usr/GNUstep/System/Tools/gnustep-config ]]
	then
		GNUSTEP_CONFIG=/usr/GNUstep/System/Tools/gnustep-config
		CFLAGS="${CFLAGS} -I/usr/GNUstep/System/Library/Headers/"
	else
		if [[ -x /usr/local/bin/gnustep-config ]]
		then
			GNUSTEP_CONFIG=/usr/local/bin/gnustep-config
		else
			GNUSTEP_CONFIG=/usr/bin/gnustep-config
		fi
	fi
	CFLAGS="$CFLAGS `${GNUSTEP_CONFIG}  --objc-flags`"
    LDFLAGS="$LDFLAGS `${GNUSTEP_CONFIG}  --base-libs --objc-libs`"
	LIBS="$LIBS -ldl"
	LIBRARIES="-lsctp -lbsd -luuid"
	CFLAGS="$CFLAGS `pkg-config  --cflags ${DEPENDENT_PKGCONFIGS}`"
	LDFLAGS="$LDFLAGS `pkg-config --libs ${DEPENDENT_PKGCONFIGS}`"
    CFLAGS="$CFLAGS -DHAVE_OPENSSL=1"
    AC_DEFINE(HAVE_OPENSSL)
	SHARED_LIBRARY_EXTENSION="so"
    DMIDECODE="/usr/sbin/dmidecode"
	;;

  *-freebsd*)
	CFLAGS="$CFLAGS -std=c99 -fPIC -DFREEBSD"
	FREEBSD_VERSION=`uname -r`
	CFLAGS="$CFLAGS  -Wno-trigraphs  -Wno-missing-field-initializers -Wmissing-prototypes -Wno-implicit-atomic-properties"
	CFLAGS="$CFLAGS -Wno-arc-repeated-use-of-weak -Wduplicate-method-match -Wno-missing-braces -Wparentheses -Wswitch -Wunused-function -Wno-unused-label"
	CFLAGS="$CFLAGS -Wno-unused-parameter -Wunused-variable -Wunused-value -Wempty-body -Wuninitialized -Wno-unknown-pragmas -Wno-shadow"
	CFLAGS="$CFLAGS -Wno-four-char-constants -Wno-conversion -Wconstant-conversion -Wint-conversion -Wbool-conversion -Wenum-conversion"
	CFLAGS="$CFLAGS -Wshorten-64-to-32 -Wpointer-sign -Wno-newline-eof -Wno-selector -Wno-strict-selector-match -Wundeclared-selector"
	CFLAGS="$CFLAGS -Wno-deprecated-implementations -Wprotocol -Wdeprecated-declarations -Wno-sign-conversion "
	CFLAGS="$CFLAGS -fobjc-arc"
	SHARED_LIBRARY_EXTENSION="so"
	if [[ -x /usr/GNUstep/System/Tools/gnustep-config ]]
	then
		GNUSTEP_CONFIG=/usr/GNUstep/System/Tools/gnustep-config
		CFLAGS="${CFLAGS} -I/usr/GNUstep/System/Library/Headers/"
	else
		if [[ -x /usr/local/bin/gnustep-config ]]
		then
			GNUSTEP_CONFIG=/usr/local/bin/gnustep-config
		else
			GNUSTEP_CONFIG=/usr/bin/gnustep-config
		fi
	fi
	CFLAGS="$CFLAGS `${GNUSTEP_CONFIG}  --objc-flags`"
    LDFLAGS="$LDFLAGS `${GNUSTEP_CONFIG}  --base-libs --objc-libs`"
	CFLAGS="$CFLAGS `pkg-config  --cflags ${DEPENDENT_PKGCONFIGS}`"
	LDFLAGS="$LDFLAGS `pkg-config --libs ${DEPENDENT_PKGCONFIGS}`"
	CFLAGS="$CFLAGS -DHAVE_OPENSSL=1"
	AC_DEFINE(HAVE_OPENSSL)
        LIBRARIES=""
    	DMIDECODE="/usr/local/sbin/dmidecode"
	;;
esac

AC_SUBST(EXE_EXT)
AC_SUBST(LIBTOOL)
AC_SUBST(RANLIB)
AC_ARG_WITH(cflags,
[  --with-cflags=FLAGS     use FLAGS for CFLAGS],
CFLAGS="$CFLAGS $withval")

AC_ARG_WITH(libs,
[  --with-libs=FLAGS       use FLAGS for extra libraries],
LIBS="$LIBS $withval")


dnl Checks for programs.

AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_RANLIB

dnl Check whether compiler supports inline
AC_C_INLINE

dnl Check for word sizes.

AC_CHECK_SIZEOF(short, 2)
AC_CHECK_SIZEOF(int, 4)
AC_CHECK_SIZEOF(long, 4)
AC_CHECK_SIZEOF(long long, 8)
SIZEOF_SHORT=$ac_cv_sizeof_short
SIZEOF_INT=$ac_cv_sizeof_int
SIZEOF_LONG=$ac_cv_sizeof_long
SIZEOF_LONG_LONG=$ac_cv_sizeof_long_long
AC_SUBST(SIZEOF_SHORT)
AC_SUBST(SIZEOF_INT)
AC_SUBST(SIZEOF_LONG)
AC_SUBST(SIZEOF_LONG_LONG)

dnl Checks for libraries.

AC_CHECK_LIB(m, log)
AC_CHECK_LIB(socket, accept)
AC_CHECK_LIB(nsl, inet_ntoa)
AC_CHECK_LIB(resolv, inet_ntop)
AC_CHECK_LIB(bind, inet_ntop)
AC_CHECK_LIB(zmq,zmq_new_ctx)

if test -z "$zmq"; then
   LIBS="$LIBS -lstdc++ -lzmq"
fi

if test -f "/usr/local/include/zmq.h"; then
    AC_DEFINE(HAVE_ZMQ_H_USR_LOCAL)
fi

if test -z "$pthread"; then
    AC_CHECK_LIB(pthread, pthread_exit, [LIBS="$LIBS -lpthread"])
fi
AC_CHECK_LIB(iconv, libiconv, [LIBS="$LIBS -liconv"])   

dnl Checks for header files.

AC_PROG_EGREP


dnl check for headers
AC_CONFIG_SECTION([Configuring HEADERS])
AC_CHECK_HEADERS(sys/sysctl.h sys/ioctl.h sys/time.h sys/types.h unistd.h sys/poll.h,,,
[
#if HAVE_SYS_IOCTL_H
#include <sys/ioctl.h>
#endif

#if HAVE_SYS_TIME_H
#include <sys/time.h>
#endif

#if HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif

#if HAVE_UNISTD_H
#include <unistd.h>
#endif

])

AC_CHECK_HEADERS(pthread.h getopt.h syslog.h iconv.h zlib.h execinfo.h stdlib.h,,,
[
#if HAVE_PTHREAD_H
#include <pthread.h>
#endif

#if HAVE_GETOPT_H
#include <getopt.h>
#endif

#if HAVE_SYSLOG_H
#include <syslog.h>
#endif


#if HAVE_ZLIB_H
#include <zlib.h>
#endif

#if HAVE_EXECINFO_H
#include <execinfo.h>
#endif

])

AC_CHECK_HEADERS(sys/socket.h)
AC_CHECK_HEADERS(sys/sockio.h)
AC_CHECK_HEADERS(net/if.h,,,
[
#if HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
]
)
AC_CHECK_HEADERS(netinet/sctp.h)
AC_CHECK_HEADERS(sctp/sctp.h)
AC_CHECK_HEADERS(netinet/in.h)
AC_CHECK_HEADERS(net/if_dl.h)
AC_CHECK_HEADERS(zmq.h)

AC_CHECK_HEADERS(sys/socket.h sys/sockio.h net/if.h netinet/in.h,,,
[
#if HAVE_SYS_SOCKET_H
#include <sys/socket.h>
#endif

#if HAVE_SYS_SOCKIO_H
#include <sys/sockio.h>
#endif

#if HAVE_NET_IF_H
#include <net/if.h>
#endif
])

AC_CHECK_HEADERS(sys/ioctl.h,,,
[[#if HAVE_SYS_IOCTL_H
# include <sys/ioctl.h> 
#endif 
]]) 

AC_CHECK_HEADERS(sys/time.h,,,
[[#if HAVE_SYS_TIME_H
# include <sys/time.h> 
#endif 
]]) 

AC_CHECK_HEADERS(sys/types.h,,,
[[#if HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif 
]]) 

AC_CHECK_HEADERS(unistd.h,,,
[[#if HAVE_UNISTD_H
# include <unistd.h> 
#endif 
]]) 

AC_CHECK_HEADERS(sys/poll.h,,,
[[#if HAVE_SYS_POLL_H
# include <sys/poll.h> 
#endif 
]]) 


AC_CHECK_HEADERS(getopt.h,,,
[[#if HAVE_GETOPT_H
# include <getopt.h>
#endif 
]]) 

AC_CHECK_HEADERS(syslog.h,,,
[[#if HAVE_SYSLOG_H
# include <syslog.h> 
#endif 
]]) 


AC_CHECK_HEADERS(zlib.h,,,
[[#if HAVE_ZLIB_H
# include <zlib.h> 
#endif 
]]) 

AC_CHECK_HEADERS(execinfo.h,,,
[[#if HAVE_EXECINFO_H
# include <execinfo.h> 
#endif 
]]) 

AC_CHECK_HEADERS(stdlib.h,,,
[[#if HAVE_STDLIB_H
# include <stdlib.h>
#endif 
]]) 

AC_CHECK_HEADERS(sys/socket.h,,,
[[#if HAVE_SYS_SOCKET_H
# include <sys/socket.h>
#endif 
]]) 

AC_CHECK_HEADERS(sys/sockio.h,,,
[[#if HAVE_SYS_SOCKIO_H
# include <sys/sockio.h> 
#endif 
]]) 

AC_CHECK_HEADERS(net/if.h,,,
[[#if HAVE_NET_IF_H
# include <net/if.h> 
#endif 
]]) 

AC_CHECK_HEADERS(netinet/in.h,,,
[[#if HAVE_NETINET_IN_H
# include <netinet/in.h> 
#endif 
]]) 


dnl Checks for typedefs, structures, and compiler characteristics.

AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[]], [[char *func = __FUNCTION__;]])],[AC_DEFINE(HAVE___FUNCTION__)],[])
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[]], [[char *func = __func__;]])],[AC_DEFINE(HAVE___FUNC__)],[])


dnl Checks for library functions.
AC_CHECK_FUNCS(gettimeofday select socket strdup getopt_long localtime_r gmtime_r backtrace srandom getline)
dnl AC_CHECK_FUNC(getopt, , AC_LIBOBJS="$AC_LIBOBJS utils/attgetopt.o")
dnl AC_SUBST(LIBOBJS)

dnl Checking if we have new TLS_method() or the older TLSv12_method()
AC_CHECK_FUNC(TLS_method, [AC_DEFINE(HAVE_TLS_METHOD)],[])

dnl Checking if we have new BN_secure_new() or the older BN_new()
AC_CHECK_FUNC(BN_secure_new, [AC_DEFINE(HAVE_BN_SECURE_NEW)],[])


dnl Checking if we have new BIO_s_secmem() or the older BIO_s_mem()
AC_CHECK_FUNC(BIO_s_secmem, [AC_DEFINE(HAVE_BIO_S_SECMEM)],[])




dnl Macro to find out which pthread_setname_np variant can be used if any 
dnl

AC_DEFUN(AC_FUNC_WHICH_PTHREAD_SETNAME_NP,
	[
		AC_CACHE_CHECK(for which type of pthread_setname_np, ac_cv_func_which_pthread_setname_np,
			[
				AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[ #include <pthread.h>]], [[
						pthread_t target_thread=0; 
						char *name="foo";
						(void) pthread_setname_np(target_thread,name);
					]])],[ac_cv_func_which_pthread_setname_np=2],[
						_au_m4_changequote([,])AC_TRY_COMPILE(
							[ #include <netdb.h> ],
							[
								char *name="foo";
								(void) pthread_setname_np(name);
							],
							ac_cv_func_which_pthread_setname_np=1,
							ac_cv_func_which_pthread_setname_np=0
						)
					 
				])
			]
		)
		if test $ac_cv_func_which_pthread_setname_np -eq 1; 
		then 
			AC_DEFINE(HAVE_PTHREAD_SETNAME_NP1)
		elif
			test $ac_cv_func_which_pthread_setname_np -eq 2; 
		then
			AC_DEFINE(HAVE_PTHREAD_SETNAME_NP2)
		fi
	]
)



dnl Extra feature checks

dnl GW_HAVE_TYPE_FROM(HDRNAME, TYPE, HAVENAME, DESCRIPTION)
AC_DEFUN(GW_HAVE_TYPE_FROM, [
	AC_CACHE_CHECK([for $2 in <$1>], gw_cv_type_$3,
		AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#include <$1>
]], [[$2 foo;]])],[gw_cv_type_$3=yes],[gw_cv_type_$3=no]))
	if test $gw_cv_type_$3 = yes; then
		AC_DEFINE($3, 1, $4)
	fi
])

dnl GW_HAVE_FUNC_FROM(HDRNAME, FUNC, HAVENAME, DESCRIPTION)
AC_DEFUN(GW_HAVE_FUNC_FROM, [
	AC_CACHE_CHECK([for $2 in <$1>], gw_cv_func_$3,
		AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[#include <$1>]], [[void *foo = $2;]])],[gw_cv_func_$3=yes],[gw_cv_func_$3=no]))
	if test $gw_cv_func_$3 = yes; then
		AC_DEFINE($3, 1, $4)
	fi
])

GW_HAVE_TYPE_FROM(sys/socket.h,
	socklen_t,
	HAVE_SOCKLEN_T,
	[Defined if there is a socklen_t in <sys/socket.h>])


GW_HAVE_FUNC_FROM(stdio.h, getopt, HAVE_GETOPT_IN_STDIO_H,
    	    	  [Does <stdio.h> declare getopt()?])
GW_HAVE_FUNC_FROM(unistd.h, getopt, HAVE_GETOPT_IN_UNISTD_H,
    	    	  [Does <unistd.h> declare getopt()?])



AC_CONFIG_SECTION([Configuring parameters])


AC_MSG_CHECKING(do we have sockaddr_in.sin_len)
AC_CHECK_MEMBER([struct sockaddr_in.sin_len],
	[ AC_DEFINE(HAVE_SOCKADDR_SIN_LEN, 1, [Do we have sockaddr_in.sin_len?]) ],
 	[],
 	[
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
])




dnl Implement --enable-debug --enable-profiling options.
dnl -------------------------------------
AC_ARG_ENABLE(profiling,
[  --enable-profiling	  enable profiling  [[disabled]]], [
	echo Using Debuging+profiling target
	CFLAGS="$CFLAGS -pg -g -O0 -D${CONFIG_DEFINE}=Debug"
	LDFLAGS="$LDFLAGS -g"
	CONFIGURATION="-configuration Debug"
	AC_DEFINE(WS_DEBUG)
]
,
[
AC_ARG_ENABLE(debug,
[  --enable-debug	  enable debugging  [[disabled]]], [
	echo Using Debuging target
	CFLAGS="$CFLAGS -g -O0 -D${CONFIG_DEFINE}=Debug"
	LDFLAGS="$LDFLAGS -g"
	CONFIGURATION="-configuration Debug"
	AC_DEFINE(WS_DEBUG)
]
,
[
	echo Using Release target
	CFLAGS="$CFLAGS -g -O2 -D${CONFIG_DEFINE}=Release"
	LDFLAGS="$LDFLAGS -g"
	CONFIGURATION="-configuration Release"
])])

./make_version

TIMESTAMP=`date -u +%Y%m%d%H%M%S`

dnl Final Output
AC_SUBST(CONFIGURATION)
AC_SUBST(PROJECT_NAME)
AC_SUBST(HAVE_OPENSSL_AS_FRAMEWORK)
AC_SUBST(HAVE_OPENSSL)
AC_SUBST(HAVE_COMMON_CRYPTO)
AC_SUBST(MAJORVER)
AC_SUBST(MINORVER)
AC_SUBST(REVISION)
AC_SUBST(STATIC_LIBS)
AC_SUBST(LIBS)
AC_SUBST(SHARED_LIBRARY_EXTENSION)
AC_SUBST(LIBRARIES)
AC_SUBST(DMIDECODE)
AC_SUBST(ARCH)
AC_SUBST(TIMESTAMP)

AC_CONFIG_SECTION([Generating output files])
AC_CONFIG_FILES([Makefile.osx])
AC_CONFIG_FILES([Makefile.linux])
AC_CONFIG_FILES([Makefile.freebsd])
AC_CONFIG_FILES([ulib.pc])
AC_CONFIG_FILES([make_buildnr.sh])
AC_CONFIG_FILES([ulib/dmi_decode_path.h])
AC_CONFIG_FILES([debian/ulib.control])
AC_OUTPUT

chmod 755 make_buildnr.sh

if [[ -f BUILDNR ]]
then
	echo "Buildnumber: `cat BUILDNR`"
else
	echo "1" > BUILDNR
	echo "Buildnumber: 1"
	./make_buildnr.sh
fi

case "$host" in
  *apple-darwin*) 
    cp Makefile.osx Makefile
    ;;
  *-linux-*)
    cp Makefile.linux Makefile
    ;;
  *-freebsd*)
    cp Makefile.freebsd Makefile
    ;;
esac

dnl LICENSE notice

AC_CONFIG_SECTION([License information])
cat <<X
+--------------------------------------------------------------------
| Project: ${PROJECT_NAME} ${VERSION}
| ${COPYRIGHT}
+--------------------------------------------------------------------
X
