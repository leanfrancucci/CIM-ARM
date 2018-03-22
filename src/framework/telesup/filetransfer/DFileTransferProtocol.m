#include <string.h>
#include "system/lang/all.h"
#include "system/util/all.h"
#include "system/io/all.h"
#include "TelesupDefs.h"
#include "TelesupExcepts.h"
#include "DFileTransferProtocol.h"


/* macro para debugging */
//#define printd(args...) doLog(0,args)
#define printd(args...)
	
@implementation DFileTransferProtocol


/**/
- initialize
{
	[super initialize];
	
	myStrictSourceFileName = 0;
	
	return self;
}

/**/
- (void) clear
{
	[super clear];
	
	myBuffer[0] = '\0';
	myFileChecksum = 0;
	myStrictSourceFileName = 0;
}


- (void) setStrictSourceFileName: (BOOL) aStrictSourceFileName { myStrictSourceFileName = aStrictSourceFileName; }
- (BOOL) isStrictSourceFileName { return myStrictSourceFileName; }	

/**/
- (char*) extractFileName: (char *) aPath
{
	if (strchr(aPath, '\\') != NULL) return strrchr(aPath, '\\') + 1;
	if (strchr(aPath, '/') != NULL) return strrchr(aPath, '/') + 1;
	return aPath;
}

/*
 *  de alla a aca
 */
- (void) downloadFile
{
	unsigned long checksum;
	int bytesToRead;
	int size;
	BOOL fileError;
	unsigned char *p;
	FILE *f;
	unsigned long ticks = getTicks();

	assert(myTelesupViewer);
	
	/* Abre el archivo local */
	f = fopen(myTargetFileName, "w+b");	
	
	//doLog(0," myTargetFileName: %s\n",myTargetFileName);
	THROW_NULL(f);
		
	TRY
		/* recibe el encabezado del archivo y envia su confirmacion */	
		[self rcvFileHeader];
		
		/* Envia el encabezado del archivo */
		[self sendFileHeaderConfirmation];	 
			
		bytesToRead = myFileSize;

	    [myTelesupViewer startFileTransfer: [self extractFileName: myTargetFileName] download: TRUE totalBytes: myFileSize];
		
		/* Comienza a recibir el archivo */
		checksum = 0;
		
		//doLog(0,"bytesToRead %d\n",bytesToRead);

		while (bytesToRead > 0) {
		
			/* Lee del Reader */	
			size = [myReader read: myBuffer qty: sizeof(myBuffer)];
//			doLog(0,"Leyo %d bytes \n",size);
			
			/**/
				
			if (size < 0)  
					THROW( GENERAL_IO_EX );

			/**/
			if (size == 0)  
					break;
					
			/* Escribe el archivo */

			if (fwrite(myBuffer, 1, size, f) <= 0)
				THROW( GENERAL_IO_EX );
//			doLog(0,"Escribio %d bytes \n",size);
			bytesToRead -= size;
	
			/* suma el checksum */
			p = &myBuffer[0];
			while (size--)
				checksum += *p++;

  		// Actualizo el observer
  		[myTelesupViewer updateFileTransfer: myFileSize-bytesToRead];

		}
	
		/* Envia confirmacion de transferecnia */
		fileError = 0;
		// << 
		// La linea de abajo hay que sacarla.
		// Esto lo hago aca porque si no tengo problemas con las colas sincronizadas.
		// Le da el control al otro hilo antes de cerrar el archivo.

//				fclose(f); 
		// >>


		if (checksum == myFileChecksum)
			[self sendTransferFileConfirmation];
		else {
			[self sendFileTransferError];
			fileError  = 1;
		}
		
	FINALLY
		
		/* Cierra el archivo */
		fclose(f);		
		
	END_TRY;

	[myTelesupViewer finishFileTransfer];

  //doLog(0,"Fin de transferencia. %d bytes transferidos en %ld ms, tasa = %6.2f bytes/seg\n", myFileSize, getTicks() - ticks, myFileSize / ((getTicks() - ticks) / 1000.0));

	if (fileError) {
		remove(myTargetFileName);	
		THROW( FT_FILE_TRANSFER_ERROR );
	}
};

/**
 *  De aca a alla
 */
- (void) uploadFile
{	
	int bytesToWrite;
	int size;
	FILE *f;
  unsigned long ticks = getTicks();
	
	/* Comprime el archivo si corresponde */
	if (myFileIsCompressed) 
			[self compressFile]; 
	
	/* el checksum del archivo y el tamanio y demas */	
	[self getFileInfo];	

	[myTelesupViewer startFileTransfer: myTargetFileName download: FALSE totalBytes: myFileSize];

	printd("--------> abre el archivo %s\n", mySourceFileName);

	/* Abre el archivo local */		
	f = fopen(mySourceFileName, "rb");
	THROW_NULL(f); 
	
	printd("--------> cantidad de bytes a escribir %d\n", myFileSize);

	bytesToWrite = myFileSize;
	
	TRY
		/* envia el encabezado de archivo y se queda esperando la acpetacion del mismo*/		
		[self sendFileHeader];
		[self waitFileHeaderConfirmation];	 
			
    if (bytesToWrite==0)	{
      // Cierra el archivo
		  fclose(f);
			EXIT_TRY;	
		  return;
    }
	
		printd("comienza a recibir el archivo\n");

		/* Comienza a recibir el archivo */
		while (bytesToWrite > 0) {
			
			/* Lee del Reader del archivo y lo envia al otro lado */
			size = fread(myBuffer, 1, sizeof(myBuffer), f);
			
			if (size < 0)  
					THROW( GENERAL_IO_EX );
			
			if (size == 0)
					break;
				
			/* Envia remotamente */
			printd("---------------> escribe %d bytes\n", size);
			if ([myWriter write: myBuffer qty: size] <= 0)  
					THROW( GENERAL_IO_EX );
				
			bytesToWrite -= size;

	   [myTelesupViewer updateFileTransfer: myFileSize - bytesToWrite];

		}
		
		/* Espera confirmacion de recepcion */
		printd("espera la confirmacion de la recepcion del archivo\n");
		[self waitTransferFileConfirmation];
	
	FINALLY
	
		/* Cierra el archivo */		
		fclose(f);		
  	[myTelesupViewer finishFileTransfer];

    //doLog(0,"Fin de transferencia. %d bytes transferidos en %ld ms, tasa = %6.2f bytes/seg\n", myFileSize, getTicks() - ticks, myFileSize / ((getTicks() - ticks) / 1000.0));

	END_TRY;	 
};

/**
 *
 */
- (void) getFileInfo
{
	unsigned long cs = 0;
	//unsigned char c;
	unsigned char buf[512];
	FILE *f;
	int i, nread;
	
	printd("toma la informacion del archivo\n");

	/* TENGO QUE HACER MEJOR TODO ESTO CON fseek() per no me anduvo bien */	
	/* la fecha y hora del archivo */	
	myFileDate = getFileDateTime(mySourceFileName);
	
	/* el tamanio del archivo */			
	f = fopen(mySourceFileName, "rb"); 
	THROW_NULL(f);
	fseek(f, 0, SEEK_END);	
	myFileSize = ftell(f);	
	fclose(f);
	
	/* Abre el archivo local */			
	f = fopen(mySourceFileName, "rb"); 
	THROW_NULL(f);

	do {
		nread = fread(buf, 1, 512, f);
		if (nread <= 0) break;
		for (i = 0; i < nread; i++) cs += buf[i];
	} while (nread > 0);

/*	while (fread((char *)&c, 1, 1, f) == 1) 
		cs += c;
	*/

	fclose(f);
	myFileChecksum = cs;	
}

/**
 * HEADER: filename\nfilesize\ncs\ndate\ncompresesedmethod
 */
- (void) sendFileHeader 
{	
	char bufd[] = "2004-12-10T12:30:25+00:00\0\0";
	
	/**/	
	datetimeToISO8106(bufd, myFileDate);

	assert(strlen(myTargetFileName) > 0);

	/* arma el file header */		
	snprintf(myBuffer, sizeof(myBuffer), "%s\n%ld\n%ld\n%s\n%s\n", 
							myTargetFileName, myFileSize, myFileChecksum, bufd,
							myFileIsCompressed ? "zip" : "uncompressed");	
	
	printd("Send File Header: %s", myBuffer);
	
	if ([myWriter write: myBuffer qty: strlen(myBuffer)] <= 0)  
		THROW( GENERAL_IO_EX );
}
	
/**/
- (void) rcvFileHeader
{	
	//          2004-12-12T12:12:+00:00		
	int size;	
	char *p = myBuffer;
	char token[255];

	/**/	
	size = [myReader read: myBuffer qty: sizeof(myBuffer)];

	if (size < 0)
		THROW( GENERAL_IO_EX );
		
	myBuffer[size] = '\0';
	
	/* reemplaza los \n por \0 para poder extraer cada campo mas facilmente */
	strrep(myBuffer, '\n', '\0');
	
	/* El nombre del archivo */
	stringcpy(token, p);
	if (strlen(token) == 0) THROW( FT_INVALID_HEADER_EX );
	
	/* el archivo recibido es igual al que se espera recibir? */	
	if (myStrictSourceFileName && strcasecmp(mySourceFileName, token) != 0)
		THROW( FT_INVALID_FILE_EX );	
	else
		stringcpy(mySourceFileName, token);
	p += strlen(mySourceFileName) + 1;
	
	/* El tamanio  */
	stringcpy(token, p);
	if (strlen(token) == 0) THROW( FT_INVALID_HEADER_EX );
	myFileSize = atol(token);
	p += strlen(token) + 1; 
	
	/* El checksum   */
	stringcpy(token, p);
	if (strlen(token) == 0) THROW( FT_INVALID_HEADER_EX );
	myFileChecksum = atol(token);	
	p += strlen(token) + 1;
	
	/* La fecha del archivo */
	stringcpy(token, p);
	if (strlen(token) == 0) THROW( FT_INVALID_HEADER_EX );
	myFileDate = ISO8106ToDatetime(token);
	p += strlen(token) + 1;	 

	/* El metodo de compresion */
	stringcpy(token, p);
	if (strlen(token) == 0) THROW( FT_INVALID_HEADER_EX );
	myFileIsCompressed = 0;
	if (strcasecmp(token, "zip") == 0) 
		myFileIsCompressed = 1;
	else if (strcasecmp(token, "uncompressed") != 0)
			THROW( FT_INVALID_HEADER_EX );		
}
	
/**/
- (void) sendFileHeaderConfirmation
{	
	if ([myWriter write: DFT_HEADER_CONFIRMATION qty: DFT_HEADER_CONFIRMATION_LEN] <= 0)
		THROW( GENERAL_IO_EX );
}
	
/**/
- (void) waitFileHeaderConfirmation      
{
	int size;
	
	size = [myReader read: myBuffer qty: sizeof(myBuffer)];
	if (size <= 0) 
		THROW( GENERAL_IO_EX );	
	myBuffer[size] = '\0';

	if (strcasecmp(myBuffer, DFT_HEADER_CONFIRMATION ) != 0) {
		//doLog(0,"waitFileHeaderConfirmation = |%s|\n", myBuffer);
		THROW_MSG(FT_FILE_TRANSFER_ERROR, myBuffer);
	}
}

/**/
- (void) sendTransferFileConfirmation
{
	if ([myWriter write: DFT_HEADER_CONFIRMATION qty: DFT_HEADER_CONFIRMATION_LEN] <= 0)
		THROW( GENERAL_IO_EX );
}

/**/
- (void) sendFileTransferError
{	
	if ([myWriter write: DFT_HEADER_ERROR qty: DFT_HEADER_ERROR_LEN] <= 0)
		THROW( GENERAL_IO_EX );
}



/**/
- (void) waitTransferFileConfirmation
{	
	int size;
	
	size = [myReader read: myBuffer qty: DFT_HEADER_CONFIRMATION_LEN];
	if (size <= 0) THROW( GENERAL_IO_EX );	
	myBuffer[DFT_HEADER_CONFIRMATION_LEN] = '\0';
	//doLog(0,"Confirmation header = |%s|\n", myBuffer);
	if (strcasecmp(myBuffer, DFT_HEADER_CONFIRMATION) != 0)
		THROW( FT_FILE_TRANSFER_ERROR );
}


/**/
- (void) compressFile
{
}

@end

