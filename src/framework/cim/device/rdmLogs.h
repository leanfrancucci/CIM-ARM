#ifndef RDM_LOGS_H
#define RDM_LOGS_H

#include "ctapp.h"

void saveMaintenanceLogToFile( unsigned char *msg ); 

void saveErrorLogToFile( unsigned char *msg, BOOL createFile ); 

#endif
