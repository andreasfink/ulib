/* ulibsctp/ulibsctp_config.h.  Generated from ulibsctp_config.h.in by configure.  */
/* ==================================================================== 
 * config.h
 * Project "ulibsctp"
 * (c) 2002-2014, Andreas Fink, Basel, Switzerland
 */ 

#ifndef CONFIG_H
#define CONFIG_H

/* Define if you have the ANSI C header files.  */
#define STDC_HEADERS 1

/* Define if your compiler supports the __func__ magic symbol. This is
   part of C99. */
/* #undef HAVE___FUNC__ */

/* Define if your compiler supports the __FUNCTION__ magic symbol. */
/* #undef HAVE___FUNCTION__ */

/* Make sure __func__ does something useful. */
#if defined(HAVE___FUNC__)
    /* Nothing to do. Life is so wonderful. */
#elif defined(HAVE___FUNCTION__)
    #define __func__ __FUNCTION__
#else
    #define __func__ "unknown"
#endif


/* Define if you have sctp/sctp.h. */
#define HAVE_SCTP_SCTP_H 1

/* Define if you have netinet/sctp.h. */
/* #undef HAVE_NETINET_SCTP_H */

/* Define if you have getopt.h. */
/* #undef HAVE_GETOPT_H */

/* Define if you have getopt(3). */
/* #undef HAVE_GETOPT */

/* Define if you have a declaration for getopt(3) in <stdio.h>. */
/* #undef HAVE_GETOPT_IN_STDIO_H */

/* Define if you have a declaration for getopt(3) in <unistd.h>. */
/* #undef HAVE_GETOPT_IN_UNISTD_H */

/* Define if you have getopt_long(3). */
/* #undef HAVE_GETOPT_LONG */

/* Define if you have the gettimeofday function.  */
/* #undef HAVE_GETTIMEOFDAY */

/* Define if you have the select function.  */
/* #undef HAVE_SELECT */

/* Define if you have the socket function.  */
/* #undef HAVE_SOCKET */

/* Define if you have the localtime_r function.  */
/* #undef HAVE_LOCALTIME_R */

/* Define if you have the gmtime_r function.  */
/* #undef HAVE_GMTIME_R */

/* Define if you have the srandom function. */
/* #undef HAVE_SRANDOM */

/* Define if you have the <fcntl.h> header file.  */
/* #undef HAVE_FCNTL_H */

/* Define if you have the <pthread.h> header file.  */
/* #undef HAVE_PTHREAD_H */

/* Define if you have the <sys/ioctl.h> header file.  */
/* #undef HAVE_SYS_IOCTL_H */

/* Define if you have the <sys/types.h> header file.  */
#define HAVE_SYS_TYPES_H 1

/* Define if you have the <unistd.h> header file.  */
#define HAVE_UNISTD_H 1

/* Define if you have the <sys/poll.h> header file.  */
/* #undef HAVE_SYS_POLL_H */

/* Define if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define if you have the <sys/socket.h> header file. */
/* #undef HAVE_SYS_SOCKET_H */

/* Define if you have the <sys/sockio.h> header file. */
/* #undef HAVE_SYS_SOCKIO_H */

/* Define if you have the <net/if.h> header file. */
/* #undef HAVE_NET_IF_H */

/* Define if you have the <netinet/in.h> header file. */
/* #undef HAVE_NETINET_IN_H */

/* Define if you have the m library (-lm).  */
/* #undef HAVE_LIBM */

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
/* #undef HAVE_SOCKLEN_T */

/* Define if the PAM headers are on the local machine */
/* #undef HAVE_SECURITY_PAM_APPL_H */

/* Define if you have <syslog.h>.  */
/* #undef HAVE_SYSLOG_H */

/* Define if you have <execinfo.h>. */
/* #undef HAVE_EXECINFO_H */

/* Define if you have the backtrace function. */
/* #undef HAVE_BACKTRACE */

/* if sctp_sendv is supported */
/* #undef ULIBSCTP_SCTP_SENDV_SUPPORTED */

/* do we have sctp_recvv */
/* #undef ULIBSCTP_SCTP_RECVV_SUPPORTED */

/* Define for various gethostbyname_r functions */
/* #undef HAVE_FUNC_GETHOSTBYNAME_R_6 */
/* #undef HAVE_FUNC_GETHOSTBYNAME_R_5 */
/* #undef HAVE_FUNC_GETHOSTBYNAME_R_3 */

/* Define for various pthread_setname_np variants */
/* #undef HAVE_PTHREAD_SETNAME_NP0 */
/* #undef HAVE_PTHREAD_SETNAME_NP1 */
/* #undef HAVE_PTHREAD_SETNAME_NP2 */

/* Define if you have getline() */
/* #undef HAVE_GETLINE */

/* if sockadd.sin_len is existing */
/* #undef HAVE_SOCKADDR_SIN_LEN */
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
