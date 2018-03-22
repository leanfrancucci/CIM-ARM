#ifndef FILE_MANAGER_H
#define FILE_MANAGER_H

#define FILE_MANAGER id

#include <Object.h>
#include "CipherManager.h"
#include "TIRemoteProxy.h"

/**
 *	Esta clase maneja todo lo relacionado con los archivos que se reciben y transfieren en la supervision a Im@s
 */
@interface FileManager : Object
{
	/*archivo utilizado por los procesos de envio de archivos*/
	FILE *filesToSnd;
	
	/*encriptador y desencriptador de archivos*/
	CIPHER_MANAGER cipherManager;
	
	/*coleccion de archivos de un directorio*/
	COLLECTION files;
		
	/*index de archivos procesados*/
	int	fIndex;
	
	/*buffer de recepcion de archivos*/
	unsigned char *bufferRxFile;

  id telesupViewer;

	/*datos de condiguracion de directorios de obtencion y alamcenamiento de archivos*/
	char destinationDir[300];
	char sourceDir[300];	
}

/**
 *	Devuelve la instancia por defecto para esta clase
 */
+ getDefaultInstance;

- (void) setTelesupViewer: (id) aViewer;

/**
*	Carga el collection con los archivos del directorio
*	@param directory directorio a cargar
* *	@param file lista donde se guardaran los nombres de los archivos a enviar
*	@return cantidad de archivos contenidos
*/
-(int) loadDirectory: (char *) directory list:(COLLECTION) files;

/**
*	Calcula el chechsum del archivo pasado por parametros
*	@param filename nombre del archivo origen
*	@return checksum del archivo
*/
-(short) getFileChecksum:(char * )filename;

/**
*	Inicializa el archivo de configuraciones a enviar
*	@param id de equipo conectado
*	@return si hay archivos a enviar
*/
-(int) initSendFilesToSend:(char *) idEq;

/**
*	Cierra el archivo con la lista de archivos a enviar
*/
- (void) deinitSendFilesToSend;

/**
*	Devuelve el siguiente archivo a enviar al cliente
*	@param filename buffer donde se almacenara el nombre del archivo a enviar
*	@return si hay otro archivo o no
*/
-(int) getNextFileToSend:(char * )filename;

/**
*	Devuelve el tamaño del archivo
*	@param filename nombre del archivo
*	@return tamaño del archivo
*/
-(long) getFilesize:(char *)FileName;

/**
*	Elimina un archivo
*	@param filename nombre del archivo
*	@return pudo o no eliminar
*/
-(int) deleteFile:(char *)FileName;

/**
*	Genera los archivos a enviar
*	@return pudo o no generar los archivos
*/
-(int) genFilesToSend;

/**
*	Genera los archivos con las retransmisiones
*	@return pudo o no generar los archivos
*/
-(int)regenFilesToSend;

/**
*	Valida la integridad de un archivo
*	@param filename archivo a validar
*	@return si el archivo es correcto
*/
-(int) validateFile: (char *) filename;

/**
*	Recibe un archivo del server
*	@param filename nombre de archivo a recibir
*	@param fileSize tamaño del archivo
*	@return si el archivo fue recibido correctamente
*/
-(int) receiveFile:(char *) filename fSize:(unsigned long) fileSize proxy:(TI_REMOTE_PROXY) rProxy;

/**
*	Envia archivo al server
*	@param filename nombre del archivo a enviar
*	@return si el archivo fue enviado correctamente
*/
-(int) sendFile:(char *)filename proxy:(TI_REMOTE_PROXY) rProxy;

/**
*	Retorna el path donde estan almacenados los archivos a enviar
*	@return path de los archivos
*/
-(char *) getDataSourceDir;

/**
*	Retorna el path donde se almacenaran los archivos recibidos en la telesupervision
*	@return path de los archivos
*/
-(char *) getDataDestinationDir;

/**
*	Copia un archivo a un directorio especificado
*	@param source path del archivo origen
*	@param destination path donde debe copiarse el archivo
*	@return si se realizo la copia o no
*/
-(int) copyFile:(char *) source To:(char *) destination;


/**
*	Extrae de un path pasado el nombre del archivo ej /data/calls/ticket.txt obtiene ticket.txt
*	@param path path del archivo
*	@param fn buffer donde se depositara el nombre del archivo
*	@return el nombre del archivo
*/
-(char *) extractFileName: (char *)path filename:(char *) fn;

/**
*	Extrae de un path pasado la extension del archivo ej /data/calls/ticket.txt obtiene txt
*	@param path path del archivo
*	@param fn buffer donde se depositara la extension
*	@return extension del archivo
*/
-(char *) extractFileExtension: (char *)path extension:(char *) ext;

/**
 *	Prepara el archivo para ser enviado, lo particion y renombra con la fecha actual o un nombre fijo
 *	@param fName nombre del archivo
 *	@param fFname nopmbre de archivo fijo, si esto es vacio se genera el nombre a partir de la fecha actual
 */
- (void) prepareFile: (char *) fName fixedFileName:(char *)fFname;

/**
 *	Libera el filemanager.
 */
- free;

/**
 *
 */
- (void) setSourceDir: (char *) aSourceDir;


@end

#endif
