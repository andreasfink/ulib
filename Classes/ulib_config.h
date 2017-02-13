/* Classes/ulib_config.h.  Generated from ulib_config.h.in by configure.  */
/* ==================================================================== 
 * config.h
 * Project "ulib"
 * Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
 */

#ifndef CONFIG_H
#define CONFIG_H

/* Define if you have the ANSI C header files.  */
#define STDC_HEADERS 1

/* Define if your compiler supports the __func__ magic symbol. This is
   part of C99. */
#define HAVE___FUNC__ 1

/* Define if your compiler supports the __FUNCTION__ magic symbol. */
#define HAVE___FUNCTION__ 1

/* Make sure __func__ does something useful. */
#if defined(HAVE___FUNC__)
    /* Nothing to do. Life is so wonderful. */
#elif defined(HAVE___FUNCTION__)
    #define __func__ __FUNCTION__
#else
    #define __func__ "unknown"
#endif

/* Define if you have getopt.h. */
#define HAVE_GETOPT_H 1

/* Define if you have getopt(3). */
/* #undef HAVE_GETOPT */

/* Define if you have a declaration for getopt(3) in <stdio.h>. */
/* #undef HAVE_GETOPT_IN_STDIO_H */

/* Define if you have a declaration for getopt(3) in <unistd.h>. */
#define HAVE_GETOPT_IN_UNISTD_H 1

/* Define if you have getopt_long(3). */
#define HAVE_GETOPT_LONG 1

/* Define if you have the gettimeofday function.  */
#define HAVE_GETTIMEOFDAY 1

/* Define if you have the select function.  */
#define HAVE_SELECT 1

/* Define if you have the socket function.  */
#define HAVE_SOCKET 1

/* Define if you have the localtime_r function.  */
#define HAVE_LOCALTIME_R 1

/* Define if you have the gmtime_r function.  */
#define HAVE_GMTIME_R 1

/* Define if you have the srandom function. */
#define HAVE_SRANDOM 1

/* Define if you have the <fcntl.h> header file.  */
/* #undef HAVE_FCNTL_H */

/* Define if you have the <pthread.h> header file.  */
#define HAVE_PTHREAD_H 1

/* Define if you have the <sys/ioctl.h> header file.  */
#define HAVE_SYS_IOCTL_H 1

/* Define if you have the <sys/types.h> header file.  */
#define HAVE_SYS_TYPES_H 1

/* Define if you have the <unistd.h> header file.  */
#define HAVE_UNISTD_H 1

/* Define if you have the <sys/poll.h> header file.  */
#define HAVE_SYS_POLL_H 1

/* Define if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define if you have the <sys/socket.h> header file. */
#define HAVE_SYS_SOCKET_H 1

/* Define if you have the <sys/sockio.h> header file. */
#define HAVE_SYS_SOCKIO_H 1

/* Define if you have the <net/if.h> header file. */
#define HAVE_NET_IF_H 1

/* Define if you have the <netinet/in.h> header file. */
#define HAVE_NETINET_IN_H 1

/* Define if you have the m library (-lm).  */
#define HAVE_LIBM 1

/* Define if you have the nsl library (-lnsl).  */
/* #undef HAVE_LIBNSL */

/* Define if you have the pthread library (-lpthread).  */
/* #undef HAVE_LIBPTHREAD */

/* Define if you have the socket library (-lsocket).  */
/* #undef HAVE_LIBSOCKET */

/* Define if you have the xml library (-lxml).  */
/* #undef HAVE_LIBXML */

/* Define if you have the z library (-lz).  */
/* #undef HAVE_LIBZ */

/* Define if there is a socklen_t in <sys/socket.h> */
#define HAVE_SOCKLEN_T 1

/* Define if the PAM headers are on the local machine */
/* #undef HAVE_SECURITY_PAM_APPL_H */

/* Define if you have <syslog.h>.  */
#define HAVE_SYSLOG_H 1

/* Define if you have <execinfo.h>. */
#define HAVE_EXECINFO_H 1

/* Define if you have the backtrace function. */
#define HAVE_BACKTRACE 1

/* Define for various gethostbyname_r functions */
/* #undef HAVE_FUNC_GETHOSTBYNAME_R_6 */
/* #undef HAVE_FUNC_GETHOSTBYNAME_R_5 */
/* #undef HAVE_FUNC_GETHOSTBYNAME_R_3 */

/* Define for various pthread_setname_np variants */
/* #undef HAVE_PTHREAD_SETNAME_NP0 */
/* #undef HAVE_PTHREAD_SETNAME_NP1 */
/* #undef HAVE_PTHREAD_SETNAME_NP2 */

/* Define if you have getline() */
#define HAVE_GETLINE 1

/* define if we have openssl1.0.x as framework installed under OS X*/
/* #undef HAVE_OPENSSL_AS_FRAMEWORK */

/* define if we have any version of openssl  */
#define HAVE_OPENSSL 1

/* define if we have common crypto installed */
#define HAVE_COMMONCRYPTO 1

/* if sockadd.sin_len is existing */
#define HAVE_SOCKADDR_SIN_LEN 1
#ifdef	HAVE_SOCKADDR_SIN_LEN
#define	HAVE_SIN_LEN HAVE_SOCKADDR_SIN_LEN
#endif

/* If we're using GCC, we can get it to check format function arguments. */
#ifdef __GNUC__
    #define PRINTFLIKE(a,b) __attribute__((format(printf, a, b)))
#else
    #define PRINTFLIKE(a, b)
#endif
                     
#endif
