#ulib
# The Universal Libary

ulib is a collection of generic useful Objective-C classes which can be used on macOS, iOS, tvOS, watchOS, Linux and probably many other Unixes. It builds on top of Foundation under Apple operating systems and GnuStep's base under Linux. It also used to work  with Cocotron in the past.

What ulib includes today is

* Dealing with Config files. (UMConfig)
* Provide a built in HTTP Server (UMHTTPServer)
* Dealing with Layers of communication protocols (UMLayer) and their asynchronous tasks (UMLayerTask)
* Dealing with Background tasks (UMBackgrounder)
* Dealing with logging (UMLogHandler)
* Objects with a history of what changed (UM)
* Synchronized Array and Dictionaries, Dictionaries with sorted keys
* Task Queues and generic Queues
* Network Sockets (TCP, UDP, SCTP) including SSL (using openSSL)
* Micosecond timers, Locks, Timers, Througput counters
* Json parsing and encoding
* RedisDB Access

# Related #

ulib is the base class of a family of libraries and applications .It gets used and extended by

* **ulibdb** a libary to query MySQL  Postgres and Redis databases in the same way.  
* **ulibasn1**  a library to make it easier to deal with ASN.1 encoded objects.
* **ulibsmpp** a library to deal with the SMPP protocol
* **ulibsctp** a library to extend ulib with SCTP specific sockets 
* **ulibm2pa** a library implementing the SS7 MTP2 protocol 
* **ulibmtp3** a library implementing the SS7 MTP3 protocol
* **ulibm3ua** a library implementing the SS7 M3UA protocol
* **ulibsccp** a library implementing the SS7 SCCP protocol
* **ulibgt** a library implementing SS7 SCCP Global Title handling
* **ulibtcap** a library implementing the SS7 TCAP protocol
* **ulibgsmmap** a library implementing the SS7 GSM-MAP protocol
* **ulibsms**  a library implementing SMS encoding/decoding functions
* **ulibdns** a library doing DNS functionality
* **schrittmacherclient** a library for applications to implement a hot/standby mechanism
* **schrittmacher** a system daemon dealing with applications in a hot/standby setup, making sure there is always one system hot and one is standby.
* **ulibcnam** a library to deal with CNAM lookups (Number to name translation)
* **messagemover** a application implementing a SS7 GSM-SMSC (commercial)
* **smsproxy** a application implementing a HLR and MSC for receiving SMS on SS7 (commercial)
* **cnam-server** a application implementing a SS7 API Server for all kinds of lookups. (commercial)

#History
Kannel (www.kannel.org) the open source SMS gateway has a library called gwlib. This library helps the  C programmer to deal with lots of daily things such as lists, dictionaries, octet strings , socket connections, config files etc. While transiting most of my code to Objective-C 2.0 to make it much easier to deal with memory management 2.0 a lot of old stuff which gwlib provided is already existing in Foundation. ulib completed Foundation with the functionality which where not in Foundation but in gwlib. Over the years many other useful functionality got added which can be used by many applications I wrote.
