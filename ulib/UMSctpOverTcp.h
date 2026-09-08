//
//  UMSctpOverTcp.h
//  ulib
//
//  Created by Andreas Fink on 11.12.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//


/*
 sctp over tcp is a encapsulation used to transport the features of sctp over a tcp link
 in the case there is no support in the kernel for sctp anymore (MacOS 11.0 and above)
 or if NAT is in the way. It is not in any RFC but comes handy for internal testing use
 of upper layers.
 
 sctp packets sent over tcp lack the feature of two sides connecting at the same time from
 both ends. This means one side must be passively listening for this to work. Keep this in
 mind when using for M2PA. In M3UA, its always a client which connects to a server.
 
 sctp packets are encapsulated in a tcap packet which is prepended with the following header
 stucture. in addition to that at setup, a header is sent which contains the "local ip" addresses
 as in the normal SCTP config so they are matched against the IP addresses in the configuration
 of the server side. This is necessary because the source port might be something else due to NAT
 or portforwarding.
 */

typedef struct sctp_over_tcp_header
{
    /* on the wire, all in network byte order */
    uint32_t    header_length;
    uint32_t    payload_length;
    uint32_t    protocolId;
    uint16_t    streamId;
    uint16_t    flags;
} sctp_over_tcp_header;


/* Flags that go into the sinfo->sinfo_flags field */
#define SCTP_OVER_TCP_NOTIFICATION     0x0010 /* next message is a notification */
#define SCTP_OVER_TCP_COMPLETE         0x0020 /* next message is complete */
#define SCTP_OVER_TCP_EOF              0x0100 /* Start shutdown procedures */
#define SCTP_OVER_TCP_ABORT            0x0200 /* Send an ABORT to peer */
#define SCTP_OVER_TCP_UNORDERED        0x0400 /* Message is un-ordered */
#define SCTP_OVER_TCP_ADDR_OVER        0x0800 /* Override the primary-address */
#define SCTP_OVER_TCP_SENDALL          0x1000 /* Send this on all associations */
#define SCTP_OVER_TCP_EOR              0x2000 /* end of message signal */
#define SCTP_OVER_TCP_SACK_IMMEDIATELY 0x4000 /* Set I-Bit */

#define SCTP_OVER_TCP_SETUP            0x0080 /* setup message reserved for SCTP over TCP */
#define SCTP_OVER_TCP_SETUP_CONFIRM    0x0040 /* setup answer  reserved for SCTP over TCP */

/* the setup message contains a payload which contains the session key so the remote can figure out which connection we are referring to
   a norma SCTP multihomed connection from a config point of view.
 
 packet payload format
 +-----------------------------------------+
 | non zero terminated UTF8String          |
 +-----------------------------------------+


*/
