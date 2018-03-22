#ifndef FILETRANSFER_H
#define FILETRANSFER_H

#include <Object.h>
#include "ctapp.h"
#include "system/io/all.h"

#include "TelesupViewer.h"

#define FILE_TRANSFER		id

#define TRANSFER_FILE_PACKET_SIZE		512

/**
 *	FileTransfer
 *		La clase que define las demas clases para transferir archivos remotamente
 */
@interface FileTransfer: Object /* {A} */
{
	TELESUP_VIEWER		myTelesupViewer;

	/* Algunos protocolos usan el reader y el writer y otros no */
	READER				myReader;	
	WRITER				myWriter;
	
	unsigned long		myFileSize;
	char 				mySourceFileName[255 + 1];
	char 				myTargetFileName[255 + 1];
	char 				myDirName[255 + 1];
	datetime_t			myFileDate;
	BOOL				myFileIsCompressed;	
}


/**/
+ new;

/**/
- initialize;

/**/
- (void) clear;

/**
 * Configura el observer de telesuprvision.
 * @param aTelesupViewer no puede ser nulo.
 */
- (void) setTelesupViewer: aTelesupViewer;
- (TELESUP_VIEWER) getTelesupViewer;

/**
 * Cuando se hace un upload() es el nombre del archivo origen que
 * se transferira (en el filesystema local).
 * Cuando se hace un download() es el nombre del archivo remoto
 * que se transfiere.
 *
 */
- (void) setSourceFileName: (char *) aFileName;
- (char *) getSourceFileName;

/**
 * Cuando se hace un upload() es el nombre de archivo remoto.
 * Y cuando se hace un download() es el nombre del nuevo archivo que
 * se crreara ebn el filessytem local. 
 */
- (void) setTargetFileName: (char *) aFileName;
- (char *) getTargetFileName;

/**
 * Indica si el archivo debe comprimirse en caso de upload() o
 * si el archivo se recibe comprimido en caso de download(). 
 */
- (void) setFileCompressed: (BOOL) aFileIsCompressed;
- (BOOL) isFileCompressed;


/**
 *	El nombre del directorio en donde debe alojarsee l archivo
 *
 */
- (void) setDirName: (const char *) aDirName;

/**
 *	Algunos protocolos necesitan el tamanio del archivo a transferir 
 */
- (void) setFileSize: (unsigned long) aFileSize;

/**
 *  Configura el reader con el que debe leer el archivo
 */
- (void) setReader: (READER) aReader;

/**
 *  Configura el writer con el que debe escribir el archivo
 */
- (void) setWriter: (WRITER) aWriter;


/**
 * Transfiere el archivo desde el sistema de archivos local
 * hacia el sistema de archivos remoto.
 */
- (void) uploadFile;

/**
 * Transfiere el archivo desde el otro extremo dela conexion hasta el sistema 
 * de archivos local
 */
- (void) downloadFile;

@end

#endif
