//
//  mysql_ssl_glue.c
//  ulib
//
//  Created by Andreas Fink on 26.09.2026.
//


/*
    the mariadb client libraries where built for an older open ssl and they call

    SSL_get_peer_certificate()

    This is however deprecated since OpenSSL 3.0 and no longer exists in OpenSSL 4.0
    One should call SSL_get1_peer_certificate() instead.
 
    This glue code simply reimplements SSL_get_peer_certificate and calls SSL_get1_peer_certificate
    We explicitly do not include openssl header files here and wokr with void so the macros
    remapping SSL_get_peer_certificate dont interfer

*/
extern void *SSL_get1_peer_certificate(void *);

void *SSL_get_peer_certificate(void *ssl)
{
    
    return SSL_get1_peer_certificate(ssl);
}
