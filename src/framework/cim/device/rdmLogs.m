#include <stdio.h>
#include <time.h>

#include "rdmLogs.h"

#define RDM_MAINTENANCE_LOG_FILE    "RDM-MaintenanceLog.csv"
#define RDM_ERROR_LOG_FILE          "RDM-ErrorLog.csv"

static FILE *fp;
static char dateTime[100];

char *getDate()
{ 
  time_t t;
  struct tm *tm;

  t=time(NULL);
  tm=localtime(&t);
  strftime(dateTime, 100, "%d-%m-%Y", tm);
  // printf (“Son las: %02d/%02d/%02d\n”, tm->tm_hour, tm->tm_min, 1900+tm->tm_sec);
  return dateTime;
}

void saveMaintenanceLogToFile( unsigned char *msg )
{
    fp = fopen( RDM_MAINTENANCE_LOG_FILE, "w+" );
    
    if ( fp == NULL ){
        printf("Error al abrir el archivo %s \n", RDM_MAINTENANCE_LOG_FILE);
        return;
    }
 
    fprintf(fp, msg);
    
    fclose(fp);
}

static char errorLogFileName[20];

void saveErrorLogToFile(unsigned char* msg, BOOL createFile)
{
    
    if ( createFile ){
        strcat( errorLogFileName, getDate() );
        strcat( errorLogFileName, RDM_ERROR_LOG_FILE );
        fp = fopen( errorLogFileName, "w+" );        
    }
        
    fp = openCreateFile( errorLogFileName ); 
    
    //fp = fopen( RDM_MAINTENANCE_LOG_FILE, "w+" );
    
    if ( fp == NULL ){
        printf( "Error al abrir el archivo %s \n", errorLogFileName );
        return;
    }
 
    fprintf(fp, msg);
    
    fclose(fp);   
   
}




