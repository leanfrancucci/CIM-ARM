#include "system/util/all.h"
#include "GetDataFileRequest.h"

//#define printd(args...) doLog(args)
#define printd(args...)


/**/
@implementation GetDataFileRequest

/**/
- (void) clearRequest
{	
	[super clearRequest];
	sendFile = TRUE;
	myAppendMode = FALSE;
	myTempFile = NULL;	
	mySourceFileName[0] = '\0';
	myTargetFileName[0] = '\0';
	myAppendMode = FALSE;
}

/**/
- (void) setAppendMode: (BOOL) anAppendMode { 	myAppendMode = anAppendMode; }
- (BOOL) getAppendMode{	return myAppendMode; }

/**/
- (void) setTargetFileName: (char *) aFileName { 	stringcpy(myTargetFileName, aFileName); }
- (char *) getTargetFileName {	return myTargetFileName; }

/**/
- (void) setSourceFileName: (char *) aFileName { 	stringcpy(mySourceFileName, aFileName); }
- (char *) getSourceFileName { return mySourceFileName; }

/**/
- (size_t) writeToRequestDataFile: (char *) aBuffer size: (size_t) aSize
{
	assert(myTempFile);
	assert(aBuffer);
	return fwrite(aBuffer, aSize, 1, myTempFile);	
}

/**/
- (void) executeRequest
{
	/* El nombre del archivo fuente */
	if (strlen(mySourceFileName) == 0) 
		sprintf(mySourceFileName, "%s/%s", [[Configuration getDefaultInstance] getParamAsString: "TEMP_PATH"], DEFAULT_SOURCE_FILENAME);

	/* El nombre del archivo destino */
	if (strlen(myTargetFileName) == 0) 
		sprintf(myTargetFileName, "%s/%s", [[Configuration getDefaultInstance] getParamAsString: "TEMP_PATH"], DEFAULT_TARGET_FILENAME);

	/**/	
	[self beginRequestDataFile];
										
	/* Crea el archivo: es posible crearlo en memoria debido a que es temporal  */
	myTempFile = fopen(mySourceFileName, "wb");
	assert(myTempFile);

	/* genera el archivo a enviar */
	[self generateRequestDataFile];
	
	/* Envia el mensaje de aceptacion */
	[myRemoteProxy sendAckDataFileMessage];

	/* Cierra el archivo generado */
	fclose(myTempFile);
	myTempFile = NULL;
	
	TRY
		
		/* envia el archivo generado */			
		[self sendRequestDataFile];
		
	FINALLY
		
		/* elimina el archivo temporal */
		/** @todo: no eliminar el archivo temporal */
		//remove(mySourceFileName);
		
	END_TRY;

	/**/	
	[self endRequestDataFile];
}


/**/
- (void) sendAckDataFileMessage
{
	/* Envia el mensaje de aceptacion estandar */	
	[myRemoteProxy newResponseMessage];	
	
	[self addContextDataFileMessage];
	
	[myRemoteProxy sendMessage];	
}

/**/
- (void) addContextDataFileMessage
{	
}

/**/
- (void) generateRequestDataFile
{
	THROW( ABSTRACT_METHOD_EX );
}
-(void) setSendFile:(BOOL) sFile 
{
	sendFile=sFile ;
}
/**/
- (void) sendRequestDataFile
{
	if (sendFile== TRUE)
	/* Envia el archivo */
	[myRemoteProxy sendFile: mySourceFileName targetFileName: myTargetFileName appendMode: myAppendMode];
}

/**/
- (void) beginRequestDataFile
{
}

/**/
- (void) endRequestDataFile
{
}

/**/
- (BOOL) reachMaxFileSize: (unsigned long) aSize maxFileSize: (unsigned long) aMaxFileSize
{
	if ((aMaxFileSize != 0) && (aMaxFileSize < aSize)) {
	//	doLog(0,"LLego al maximo tamaño de archivo permitido!\n");
		return TRUE;
	}

	return FALSE;
}


@end
