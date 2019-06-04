#ifndef RDM_LOGS_H
#define RDM_LOGS_H

#include "ctapp.h"

static unsigned char errorOccurenceLogFileName[] = "RDM-ErrorOccurenceLog.csv";
static unsigned char informationLogFileName[]    = "RDM-InformationLog.csv";
static unsigned char errorLogFileName[]          = "RDM-ErrorLog.csv";
static unsigned char operationLogFileName[]      = "RDM-OperationLog.csv";
static unsigned char rejectLogFileName[]         = "RDM-RejectLog.csv";


void saveMaintenanceLogToFile( unsigned char *msg ); 

void saveLogToFile( unsigned char *msg, BOOL createFile, unsigned char *fileName ); 

#endif
