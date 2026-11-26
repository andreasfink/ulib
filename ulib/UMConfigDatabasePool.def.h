//
//  UMConfigDatabasePool.def.h
//  ulib
//
//  Created by Andreas Fink on 26.11.2026.
//

ULIBCONFIG_STRING(o,"host",_host,"host",10,"")
ULIBCONFIG_STRING(o,"database-name",_databaseName,"database_name",11,"")
ULIBCONFIG_STRING(o,"driver",_driver,"driver",12,"")
ULIBCONFIG_STRING(o,"user",_user,"user",13,"")
ULIBCONFIG_STRING(o,"pass",_pass,"pass",14,"encrypt")
ULIBCONFIG_INTEGER(o,"port",_port,"port",15,"")
ULIBCONFIG_INTEGER(o,"min-sessions",_minSessions,"min_sessions",16,"")
ULIBCONFIG_INTEGER(o,"max-sessions",_maxSessions,"max_sessions",17,"")
ULIBCONFIG_STRING(o,"socket",_socket,"socket",18,"")
ULIBCONFIG_REAL(o,"ping-intervall",_pingIntervall,"ping_intervall",19,"")
ULIBCONFIG_STRING(o,"storage-type",_storageType,"storage_type",20,"")
ULIBCONFIG_STRING(o,"version",_version,"version",21,"")
ULIBCONFIG_STRING(o,"encryption-key",_encryptionKey,"encryption_key",22,"nodb")

