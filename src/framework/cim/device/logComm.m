#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "util.h"
#include "logComm.h"
#include "log.h"


//#define _PCTEST_ 
#define MAX_LOG_SIZE 262144L
//#define MAX_LOG_SIZE 300

#define LOGCONFIG_FILE	"logConfig.txt"

#ifdef __UCLINUX
#define LOGCOMM_FILE	BASE_PATH "/bin/logComm.txt"
#define LOGCOMM2_FILE	BASE_PATH "/bin/logComm2.txt"
#else
#define LOGCOMM_FILE	"logComm.txt"
#define LOGCOMM2_FILE	"logComm2.txt"
#endif

/*
	Logueo de comunicacion
*/


static char *charSet = "0123456789ABCDEF";
static char buffer[2000];
static long fileSize;

char *getHexFrame(unsigned char *data, int qty)
{
	char *str;
	int i;

	str = buffer;
    for ( i = 0; i < qty ; ++i ){
        *str = charSet[data[i] / 16];
        ++str;
        *str = charSet[data[i] % 16];
        ++str;
        *str = ' ';
        ++str;
	}    
    *str = '\n';
    ++str;
    *str = 0;
	
    return buffer;
}

static FILE *fp;
static char logType;

/*
FILE * openCreateFile( char *fileName )
{
	FILE *fpAux;
    //Levanto el archivo con los encabezados de cada uno de los archivos
#ifdef __UCLINUX
    fpAux = fopen( fileName, "a+bx");
#else
    fpAux = fopen( fileName, "a+b");
#endif
    if( fpAux ) {
	    fclose(fpAux);
	    fpAux = fopen( fileName, "r+b");
	    if( fpAux ) 
		    fseek( fpAux, 0, SEEK_END );
	}
  	fseek( fpAux, 0, SEEK_END );
	fileSize = ftell(fpAux);
	return fpAux;
}
*/
void openConfigFile ( void )
{
	fp = openCreateFile( LOGCONFIG_FILE );
    fseek( fp, 0, SEEK_SET );
	if (!fread(&logType, 1,1,fp)){
		logType = '2';
		fwrite( &logType, 1, 1, fp );
	}
	fclose(fp);
	logType -= '0';
    //************************* logcoment
//	doLog(0,"log type! %d\n", logType);fflush(stdout);
	fp = openCreateFile( LOGCOMM_FILE );
  	fseek( fp, 0, SEEK_END );
	fileSize = ftell(fp);
    //************************* logcoment
//	doLog(0,"log type! %d fileSize %ld\n", logType, fileSize);fflush(stdout);
}


char *directionList[]= {
	 "R: "
	,"W: "
};

void logSaveToFile( char *strDateTime, char * strLog )
{
	char auxBuf[100];

    fileSize += ( strlen( strLog ) + strlen( strDateTime ));
	if ( fileSize > MAX_LOG_SIZE ){
		//tengo que renombrar el archivo y crear uno nuevo:
		fclose(fp);
		//sprintf(auxBuf, "rm %s\n", LOGCOMM2_FILE );
		//system(auxBuf);	
        
        if(remove(LOGCOMM2_FILE)==0)
            printf("El archivo se borro satisfactoriamente\n");
        else 
            printf("El archivo NO se borro satisfactoriamente\n");
    //************************* logcoment
//		doLog(0,"Creating new LOGCOMMFILE, fileSize %ld!!\n", fileSize );
		//sprintf(auxBuf, "mv %s %s\n", LOGCOMM_FILE, LOGCOMM2_FILE );
		//system(auxBuf);	
            
        if(rename(LOGCOMM_FILE,LOGCOMM2_FILE)==0)// Renombramos el archivo
            printf("El archivo se renombro satisfactoriamente\n");
        else
            printf("No se pudo renombrar el archivo\n");            
        
  //      system("PAUSE");
		fp = openCreateFile( LOGCOMM_FILE );
		fileSize = 0;
        
	}
	fwrite( strDateTime, 1, strlen(strDateTime), fp );
	fwrite( strLog, 1, strlen(strLog), fp );
	fflush( fp );
}

char strFormat[20];

void logFrame( unsigned char devId, unsigned char *frame, int n, char direction )
{	
	char *str;

	if ( logType != NO_LOG ){
		str = getHexFrame(frame, n);	

		//sprintf(strFormat, "%s | %d | %s", strDate, devId, directionList[direction] );
		sprintf(strFormat, "%lu - %d | %s", time(NULL), devId, directionList[direction] );

		if ( logType == FILE_LOG || logType == FULL_LOG || logType == VALS_LOG  ){
			logSaveToFile( strFormat, str );
		} else {
			printf("%s %s", strFormat, str);
			fflush(stdout);
		}
	}
}	

void logStr( char *str )
{	
	/*if ( !fp ) 
		openLogFile();

	fwrite( str, 1, strlen(str), fp );
	fflush( fp );*/
}	


int getLogType( void )
{
	return logType;
}
