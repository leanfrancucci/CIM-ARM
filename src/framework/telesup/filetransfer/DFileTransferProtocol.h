#ifndef DFILETRANSFERPROTOCOL_H_
#define DFILETRANSFERPROTOCOL_H_

#define D_FILE_TRANSFER_PROTOCOL		id

#include <stdlib.h>
#include <stdio.h>
#include <Object.h>
#include "ctapp.h"
#include "FileTransfer.h"
#include "system/io/all.h"
#include "system/util/all.h"

#define 		DFT_HEADER_CONFIRMATION 		"ok\n"
#define 		DFT_HEADER_CONFIRMATION_LEN 	3

#define 		DFT_HEADER_ERROR 				"Error\n"
#define 		DFT_HEADER_ERROR_LEN 			6

/**
 *	StreamFileTransfer
 *		Transfiere archivos escribiendo y leyendo sobre un Writer y un Reader.
 *		El Writer y Reader pueden escribir/leer sobre un socket, sobre un driver o
 *		o cualquier otra cosa
 */
@interface DFileTransferProtocol: FileTransfer
{
	char			myBuffer[TRANSFER_FILE_PACKET_SIZE];
	unsigned long	myFileChecksum;
	BOOL			myStrictSourceFileName;
	 
}


/**
 *
 */
- (void) setStrictSourceFileName: (BOOL) aStrictSourceFileName;
- (BOOL) isStrictSourceFileName;

/**
 *	Envia el encabezado del archivo a enviar.
 *  header:         FileName   -     FileSize    -      Checksum        -       Date
 *            											4 bytes                ISO8106
 */
- (void) sendFileHeader;
	
/**
 * Qued a la espera del encabezado del archivo
 */
- (void) rcvFileHeader;
	
/**
 * Envia la confirmacion del encabezado del archivo: "OK".
 */
- (void) sendFileHeaderConfirmation;
	
/**
 * Queda a la espera de la confirmación del encabezado de archivo: "OK"
 */
- (void) waitFileHeaderConfirmation;

/**
 * Envia la confirnacion de la transferencia completa del archivo.
 */
- (void) sendTransferFileConfirmation;

/**
 * Envia un mensaje de transferencia erronea.
 */
- (void) sendFileTransferError;
	
/**
 * Queda a la espera de la confirnmacion de la trandferencia del archuivo.
 */
- (void) waitTransferFileConfirmation;

/**
 * configura los datos del archivo a transferir 
 */	
- (void) getFileInfo;

/**
 * Comprime el archivo antes de hacer un upload(). 
 */	
- (void) compressFile;
		
@end

#endif
