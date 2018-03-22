#ifndef CMANAGER_H
#define CMANAGER_H

#define CIPHER_MANAGER id

#include <Object.h>
#include "system/io/all.h"

/**
 *	Esta clase implementa los procesos de cifrado y descifrado de 
 *	archivos, com el metodo implementado en Im@s 
 */
@interface CipherManager : Object
{
	READER	myReader;
	WRITER	myWriter;
}

/**
*	Encripta un archivo guardandolo con el mismo nombre pero con extension .enc
*	@param filename nombre del archivo origen
*	@return si la operacion fue concluid con exito
*/
-(int) encodeFile: (char *) filename destination: (char *) aDestination size: (long)fSize;

/**
*	Desencripta un archivo guardandolo con el mismo nombre pero con extension .dec
*	@param filename nombre del archivo origen
*	@return si la operacion fue concluida con exito
*/
-(int) decodeFile: (char *) filename destination: (char *) aDestination size: (long)fSize;

/**
 *	Devuelve el Writer de acceso a los archivos.
 */
- (WRITER) getWriter;

/**
 *	Devuelve el Reader de acceso a los archivos.
 */
- (READER) getReader;

/**
 *	Libera el ciphermanager.
 */
- free;

@end

#endif
