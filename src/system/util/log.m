#include <stdio.h>
#include <stdlib.h>
#include "state_machine.h"
#include "OMutex.h"
#include "system/os/all.h"
#include "util.h"
#include "File.h"

#ifdef __UCLINUX
#define LOGFILE 	BASE_PATH "/bin/log.txt"
#define LOGOLDFILE 	BASE_PATH "/bin/log2.txt"
#define LOGCONFIGF  BASE_PATH "/bin/debugLog"
#else
#define LOGFILE 	"log.txt"
#define LOGOLDFILE 	"log2.txt"
#define LOGCONFIGF  "logC.txt"
#endif

static FILE *fpLog;
static OMUTEX myMutexLog = NULL;
#define MAX_LOG_BUFFER 1024
static char lineFmt[MAX_LOG_BUFFER];
#define MAX_FILE_SIZE 131072L
#define MAX_FILE_SIZE_BIG 524288L
//#define MAX_FILE_SIZE 2000L
static long fileSize;
static long maxFileSize;
static int isFirstLog = 0;

FILE * openCreateFile( char *fileName )
{
	FILE *fp;
    
    printf("openCreateFile en log.m");
	//Levanto el archivo con los encabezados de cada uno de los archivos
#ifdef __UCLINUX
	fp = fopen( fileName, "a+bx");
#else
	fp = fopen( fileName, "a+b");
#endif

	if( fp ) {
		fclose(fp);
		fp = fopen( fileName, "r+b");
		if( fp ) {
//			setvbuf(fpLog, NULL, _IOFBF, 128);
			fseek( fp, 0, SEEK_END );
			fileSize = ftell(fp);	
		}
	}
	return fp;
  
}


void initLog( void )
{
	fpLog = openCreateFile( LOGFILE );
	if ([File existsFile: LOGCONFIGF]){
	//	printf("DOLOG initlog file size bidg\n"); fflush(stdout);
		maxFileSize = MAX_FILE_SIZE_BIG;
	} else {
	//	printf("DOLOG initlog file size samall\n"); fflush(stdout);
		maxFileSize = MAX_FILE_SIZE;
	}

	myMutexLog = [OMutex new];
	isFirstLog = 1;
}	


void doLog( char addHour, const char *fmt, ... )
{
    
	va_list ap;
	char auxBuf[100];

   return;
	[myMutexLog lock];
	
	TRY

		va_start(ap, fmt);	

#ifdef __ARM_LINUX
        vsnprintf(lineFmt, MAX_LOG_BUFFER, fmt, ap);
		lineFmt[MAX_LOG_BUFFER - 1] = '\0';
#else
        vsnprintf(lineFmt, MAX_LOG_BUFFER, fmt, ap);
		lineFmt[MAX_LOG_BUFFER - 1] = '\0';
		dprintf ("%s", lineFmt);	
#endif
/*
  	//SOLE-- Aca modifique para optimizar la comunicacion con los validadores:
		addHour = 0;
		if ( addHour || isFirstLog ) {
			curDate = getDateTime();
			localtime_r(&curDate, &brokenTime);
			ticks = getTicks() - ticks;

			if ( isFirstLog ) {
				strftime (auxBuf, 20, "%d-%m %H:%M:%S ", &brokenTime);
				isFirstLog = 0;
			} else
				strftime (auxBuf, 20, "%H:%M:%S ", &brokenTime );
		
			fwrite( &auxBuf, 1, strlen(auxBuf), fpLog );
			sprintf(auxBuf, "ticks> %u ", ticks);
			fwrite( &auxBuf, 1, strlen(auxBuf), fpLog );
		}
	// FIN SOLE -- Comente la escritura en el log de la fecha hora del sistema, nada mas que eso..
	
*/
		fwrite( &lineFmt, 1, strlen(lineFmt), fpLog );
		fflush( fpLog );

		
	FINALLY
		[myMutexLog unLock];
		va_end(ap);
	END_TRY
	
	
	
}



void doLog_( const char *fmt, ... )
{
	va_list ap;

	[myMutexLog lock];
	TRY
		va_start(ap, fmt);	
		vprintf ( fmt, ap );	
		vsnprintf(lineFmt, MAX_LOG_BUFFER, fmt, ap);
		lineFmt[MAX_LOG_BUFFER - 1] = '\0';
	FINALLY
		[myMutexLog unLock];
		va_end(ap);
	END_TRY
	
}

