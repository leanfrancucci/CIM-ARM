#ifndef __DMODEMPROTO_H
#define __DMODEMPROTO_H

#define DMODEM_PROTO id

#include "Object.h"
#include "system/io/all.h"
#include "dmodem.h"
#include "DModemExcepts.h"


/**
 * 
 */
@interface DModemProto:  Object	       
{
	int				myFlags;
	
	READER			myReader;
	WRITER			myWriter;
	
	DModemConfig dm;
}

/**
 *
 */
+ new;

/**
 *
 */
- initialize;

/** 
 * True si se quiere el driver con lecturas bloqueantes y falso en caso contrario.
 */
- (void) setSpecialReadBlockMode: (int) aMode;

/** 
 *	Configura el reader para las lecturas realizadas.
 */
- (void) setReader: (READER) aReader;

/** 
 * Configura el writer para las lecturas realizadas.
 */
- (void) setWriter: (WRITER) aWriter;


/**
 *
 */
- (void) open;

/**
 *
 */
- (void) close;

/**
 *
 */
- (void) connect;

/**
 *
 */
- (void) waitConnection;

/**
 *
 */
- (int) read: (char *) aBuf qty: (int) aQty;

/**
 *
 */
- (int) write: (char *) aBuf qty: (int) aQty;


/* Metodo privado */
- (int) __dm_writeSerial: (unsigned char *)aBuf qty: (int) aQty;
/* Metodo privado */
- (int) __dm_readSerial: (int) aRcvType data: (int *) aPData;


@end

#endif

