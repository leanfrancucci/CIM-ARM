#ifndef GETDATAFILEREQUEST_H
#define GETDATAFILEREQUEST_H

#define GET_DATA_FILE_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "Request.h"

#define DEFAULT_TEMP_FILENAME 		"TempFile.dat"
#define DEFAULT_SOURCE_FILENAME		"SourceFile.dat"
#define DEFAULT_TARGET_FILENAME		"TargetFile.dat"


/*
 *	Define el tipo de todos los Request que son utilizados
 *  para transferir archivos que el sistema remoto consulte informacion sobre
 *  el estado del sistema.
 */
@interface GetDataFileRequest: Request /* {Abstract} */
{
	BOOL		sendFile;
	BOOL		myAppendMode;
	FILE		*myTempFile;
	char		mySourceFileName[255];
	char		myTargetFileName[255];
}

/**/
- (void) setAppendMode: (BOOL) anAppendMode;
- (BOOL) getAppendMode;

/**/	
- (void) setTargetFileName: (char *) aFileName;
- (char *) getTargetFileName;

/**/
- (void) setSourceFileName: (char *) aFileName;
- (char *) getSourceFileName;

/**
 *
 * Visibility: Protected
 */
- (size_t) writeToRequestDataFile: (char *) aBuffer size: (size_t) aSize;

/**
 *
 */
- (void) sendAckDataFileMessage;

/**
 *
 */
- (void) addContextDataFileMessage;

/**
 *
 */
- (void) generateRequestDataFile;

/**
 *
 */
- (void) sendRequestDataFile;

/**
 *
 */
- (void) beginRequestDataFile;

/**
 *
 */
- (void) endRequestDataFile;

/**
 *
 */
-(void) setSendFile:(BOOL) sFile;

/** 
 * Verifica si un buffer llego al maximo tamaño
 */
- (BOOL) reachMaxFileSize: (unsigned long) aSize maxFileSize: (unsigned long) aMaxFileSize;

@end

#endif
