//
//  UMSocketDefs.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


typedef enum UMSocketError
{
	UMSocketError_has_data_and_hup          = 2,
	UMSocketError_has_data                  = 1,
    UMSocketError_no_error					= 0,
	UMSocketError_already_bound				= -1,
	UMSocketError_already_listening			= -2,
	UMSocketError_insufficient_privileges	= -3,	/* EACCES */
	UMSocketError_invalid_file_descriptor	= -4,	/* EBADF */
	UMSocketError_not_bound					= -5,	/* EDESTADDRREQ */
	UMSocketError_already_connected			= -6,	/* EINVAL on listen */
	UMSocketError_not_a_socket				= -7,	/* ENOTSOCK */
	UMSocketError_not_supported_operation	= -8,	/* EOPNOTSUPP */
	UMSocketError_generic_listen_error		= -9,
	UMSocketError_generic_close_error		= -10,
	UMSocketError_execution_interrupted		= -11,
	UMSocketError_io_error					= -12,	/* EIO */
	UMSocketError_sctp_bindx_failed_for_all	= -13,
	UMSocketError_address_already_in_use	= -14, /* EADDRINUSE */
	UMSocketError_address_not_available		= -15, /* EADDRNOTAVAIL */
	UMSocketError_address_not_valid_for_socket_family = -16, /* EAFNOSUPPORT */
	UMSocketError_socket_is_null_pointer    = -17, /* EDESTADDRREQ */
	UMSocketError_pointer_not_in_userspace	= -18,
	UMSocketError_empty_path_name			= -20,
	UMSocketError_loop						= -21,
	UMSocketError_name_too_long				= -22,
	UMSocketError_not_existing				= -23,
	UMSocketError_not_a_directory			= -24,
	UMSocketError_readonly					= -25,
	UMSocketError_generic_bind_error		= -26,
    UMSocketError_try_again		            = -27,  /* EAGAIN */
    UMSocketError_no_data                   = -28,
    UMSocketError_generic_error				= -29,
    UMSocketError_timed_out                 = -30,
    UMSocketError_connection_refused        = -31,
    UMSocketError_connection_reset          = -32,  /* ECONNRESET */
    UMSocketError_no_buffers                = -33,  /* ENOBUFS */
    UMSocketError_no_memory                 = -34,  /* ENOMEM */
    UMSocketError_nonexistent_device        = -35,  /* ENXIO */
    UMSocketError_user_quota_exhausted      = -36,  /* EDQUOT */
    UMSocketError_efbig                     = -37,  /* EFBIG */
    UMSocketError_network_down              = -38,  /* ENETDOWN */
    UMSocketError_network_unreachable       = -39,  /* ENETUNREACH */
    UMSocketError_no_space_left             = -40,  /* ENOSPC */
    UMSocketError_pipe_error                = -41,  /* EPIPE */
    UMSocketError_not_listening             = -42,
    UMSocketError_invalid_advertize_domain  = -43,
    UMSocketError_invalid_advertize_type    = -44,
    UMSocketError_invalid_advertize_name    = -45,
    UMSocketError_no_such_process           = -46, /* ESRCH */
    UMSocketError_host_down                 = -47,  /* EHOSTDOWN*/
    UMSocketError_not_known                 = -999
} UMSocketError;


typedef enum UMSocketType
{
	UMSOCKET_TYPE_NONE			= 0x00,
	UMSOCKET_TYPE_TCP			= 0x01,
	UMSOCKET_TYPE_UDP			= 0x02,
	UMSOCKET_TYPE_SCTP			= 0x03,
	UMSOCKET_TYPE_USCTP			= 0x04,
	UMSOCKET_TYPE_DNSTUN		= 0x05,
	UMSOCKET_TYPE_UNIX			= 0x06,
	UMSOCKET_TYPE_MEMORY		= 0x07,
	UMSOCKET_TYPE_SERIAL		= 0x08,
	
	UMSOCKET_TYPE_TCP4ONLY		= 0x41,
	UMSOCKET_TYPE_UDP4ONLY		= 0x42,
	UMSOCKET_TYPE_SCTP4ONLY		= 0x43,
	UMSOCKET_TYPE_USCTP4ONLY	= 0x44,
	
	UMSOCKET_TYPE_TCP6ONLY		= 0x61,
	UMSOCKET_TYPE_UDP6ONLY		= 0x62,
	UMSOCKET_TYPE_SCTP6ONLY		= 0x63,
	UMSOCKET_TYPE_USCTP6ONLY	= 0x64,
} UMSocketType;

typedef	enum UMSocketStatus
{
	UMSOCKET_STATUS_FOOS	= -1,
	UMSOCKET_STATUS_OFF		= 100,
	UMSOCKET_STATUS_OOS		= 101,
	UMSOCKET_STATUS_IS		= 102,
} UMSocketStatus;

typedef	enum UMSocketConnectionDirection
{
	UMSOCKET_DIRECTION_UNSPECIFIED = 0,
	UMSOCKET_DIRECTION_OUTBOUND	= 1,
	UMSOCKET_DIRECTION_INBOUND	= 2,
	UMSOCKET_DIRECTION_PEER		= (UMSOCKET_DIRECTION_OUTBOUND | UMSOCKET_DIRECTION_INBOUND),
} UMSocketConnectionDirection;
