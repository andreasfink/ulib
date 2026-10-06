#ulib
# The Universal Libary

ulib is a collection of generic useful Objective-C classes which can be used on 
macOS, iOS, tvOS, watchOS, Linux, FreeBSD and probably many other Unixes.
It builds on top of Foundation under Apple operating systems and GnuStep's base
under Linux and FreeBSD. It also used to work with Cocotron in the past and might work
with ObjFW in the future.

Note: Gnustep must be compiled with clang and libobjc2 runtime so ARC can work. 
gcc does not support ARC unfortunately and probably never will.
Debian13's built in Gnustep is not compatible. FreeBSD 15.1's gnustep is having ARC
supoprt.

What ulib includes today is

* Dealing with Config files. (UMConfig)
* Provide a built in HTTP Server (UMHTTPServer) and client
* Dealing with Layers of communication protocols (UMLayer) and their asynchronous tasks (UMLayerTask)
* Dealing with Background tasks (UMBackgrounder)
* Dealing with logging (UMLogHandler, UMLogFeed)
* Objects with a history of what changed (UMDirtyString, UMDirtyDouble, UMDirtyDate ...). Useful for objects mirroring database records
* Synchronized Array and Dictionaries, Dictionaries with sorted keys (UMSynchronizedArray,UMSynchronizedDictionary,UMSynchronizedSortedDictionary)
* Task Queues and generic Queues
* Network Sockets (TCP, UDP, SCTP) including SSL (using openSSL) (UMSocket)
* Micosecond timers, Locks, Timers, Througput counters
* Json parsing and encoding
* RedisDB Access
* Mysql and Postgres Database Access
* ZeroMQ support
* ASN1 Encoding/Decoding
* sctp socket support (not supported anymore under MacOS due to now lacking kernel functionality. Thanks to Apple...)
* remote procedure calls (UMRpcServer, UMRpcClient)

# Related #

ulib is the base class of a family of libraries and applications .It gets used and extended by

* **ulibmtp3** a library implementing the SS7 MTP3 M2PA and M3UA protocols
* **ulibsccp** a library implementing the SS7 SCCP protocol
* **ulibtcap** a library implementing the SS7 TCAP protocol
* **ulibgsmmap** a library implementing the SS7 GSM-MAP protocol
* **ulibsms**  a library implementing SMS encoding/decoding functions
* **ulibsmpp** a library to deal with the SMPP protocol
* **ulibdns** a library doing DNS functionality
* **schrittmacherclient** a library for applications to implement a hot/standby mechanism
* **schrittmacher** a system daemon dealing with applications in a hot/standby setup, making sure there is always one system hot and one is standby.
* **messagemover** a application implementing a SS7 GSM-SMSC (commercial)
* **estp** a application implementing a SS7 packet router (enhanced signaling transfer point) (commercial)
* **smsproxy** a application implementing a HLR and MSC for receiving SMS on SS7 (commercial)
* **gsm-api** a application implementing a SS7 API Server for all kinds of lookups. (commercial)

# Merged functionalities #

Release 6.0 (2026) merged in some functionality which where previously in separately libraries
ulibasn1   ASN1 functions 
ulibsctp   sctp socket functions 
uibldb     mysql and postgres database functions
ulibrppc   remote procedure call functions


#History
Kannel (www.kannel.org) the open source SMS gateway has a library called gwlib. This 
library helps the  C programmer to deal with lots of daily things such as lists, 
dictionaries, octet strings , socket connections, config files etc. While transiting 
most of my code to Objective-C 2.0 to make it much easier to deal with memory 
management a lot of old stuff which gwlib provided already existing in 
Foundation. ulib completed Foundation with the functionality which where not in 
Foundation but in gwlib. Over the years many other useful functionality got added 
which can be used by many applications I wrote. So ulib became universal in many ways.
