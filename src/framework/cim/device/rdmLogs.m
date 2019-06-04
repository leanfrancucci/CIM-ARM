#include <stdio.h>
#include <time.h>

#include "rdmLogs.h"

#define RDM_MAINTENANCE_LOG_FILE    "RDM-MaintenanceLog.csv"

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

static char logFileName[30];

void saveLogToFile(unsigned char* msg, BOOL createFile, unsigned char *fileName)
{
    if ( createFile ){
        strcat( logFileName, getDate() );
        strcat( logFileName, fileName );
        fp = fopen( logFileName, "w+" );        
    }else
        fp = openCreateFile( logFileName ); 
     
    if ( fp == NULL ){
        printf( "Error al abrir el archivo %s \n", logFileName );
        return;
    }
 
    fprintf(fp, msg);
    
    fclose(fp);   
   
}




