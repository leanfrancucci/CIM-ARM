#include <stdio.h>

#include "rdmLogs.h"
#include "system/util/log.h"

#define RDM_MAINTENANCE_LOG_FILE "RDM-MaintenanceLog.csv"

static FILE *fp;

void saveMaintenanceLogLineToFile( unsigned char *msg, int len )
{
    fp = openCreateFile( RDM_MAINTENANCE_LOG_FILE );

    unsigned short aux = SHORT_TO_L_ENDIAN(*(unsigned short *)(msg));
    
    fprintf(fp,"Aceptados: %d", aux);
    
    fclose(fp);
}


