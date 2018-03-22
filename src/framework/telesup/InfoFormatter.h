#ifndef INFOFORMATTER_H
#define INFOFORMATTER_H

#define INFO_FORMATTER id

#include <Object.h>
#include "ctapp.h"
#include "system/db/all.h"

/**
 * Define la interface y alguno smetodos base para las subclases que formatean
 * la informacion intercambiada entre el sistema local y los sistemas remotos.
 * Cada subclase InfoFormatter redefine los metodos necesarios para adecuar la informacion
 * al formato adecuado.
 *
 */
@interface InfoFormatter: Object /* {Abstract} */
{
	char		*myBuffer;
	char		*myOriginalBuffer;
	int			myTelesupId;
	char 		myTempBuffer[255];
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
 * Devuelve la cantidad de bytes formateados.
 */
- (int) getLenInfo; 

/**
 *	Setea el id de supervision.
 */
- (void) setTelesupId: (int) aTelesupId;

/**
 * Configura el buffer en donde se copian los datos formateados.
 * @param (char *)  en buffer se copian, aBuffer debe apuntar a una zona de memoria
 * del tamanio suficiente como para albergar los datos formateados.
 */
- (void) setBuffer: (char *) aBuffer;

 
/** 
 * Copia el long  en el buffer transformado al formato adecuado. 
 */
- (int) writeLong: (long) aValue;
- (long) readLong;


/** 
 * Copia el short en el buffer transformado al formato adecuado.
 */
- (int) writeShort: (short) aValue;
- (short) readShort;

/** 
 * Copia el char en el buffer transformado al formato adecuado.
 */
- (int) writeByte: (int) aValue;
- (int) readByte;

/** 
 * Copia el char en el buffer transformado al formato adecuado.
 */
- (int) writeChar: (char) aValue;
- (int) readChar;

/** 
 * Copia el buffer transformado al formato adecuado.
 */
- (int) writeByteStream: (void *)aValue qty: (int) aQty;

/**
 * Copia en @param aBuffer @param aQty bytes.
 * @result (char *) devuelve aBuffer.
 */
- (char *) readByteStream: (void *) aBuffer qty: (int) aQty;

/** 
 * Copia el String en el buffer interno transformado al formato adecuado.
 * Si el tamanio del string es menor que aQty entonces copia un '\0' final,
 * si es igual no copi un '\0' final, 
 * y si es mayor entonces copia solo aQty caracteres sin '\0' final.
 * @param (int) aQty es el tamanio maximo de la cadena a escribir.
 * El buffer interno se incrementa aQty lugares a pesar que la cadena escrita
 * sea de menor longitud que el valor aQty.
 */
- (int) writeString: (char *)aValue qty: (int) aQty;

/**
 * Lee el string agregando un '\0' final.
 * Si se encuentra un '\0' antes de completar aQty bytes leidos se devuelven
 * los que se leyeron hasta el momento.
 * @param (int) aQty es el tamanio maximo de la cadena a leer.
 * @result (char *) devuelve aBuffer.
 */
- (char *) readString: (char *) aBuffer qty: (int) aQty;


/** 
 * Copia el String en el buffer transformado a formato BCD.
 * La cadena resultante BCD tendra una longitud de aQty / 2 bytes.
 * @aQty indica el tamano de la cadena ntes de ser convertida a BCD.
 */
- (int) writeBCD: (char *)aValue qty: (int) aQty;

/**
 * Copia en @param aBuffer @param aQty / 2 bytes convertidos desde el format BCD.
 * @aQty es el tamano de la cadena que se quiere obtener, es decir, del buffer interno
 * se leeran aQty / 2 bytes pero se convierte a cadena ascii de tamanio dos veces superior.
 * @result (char *) devuelve aBuffer.
 */
- (char *) readBCD: (char *)aBuffer qty: (int) aQty;

/** 
 * Copia el valor boolean en el buffer transformado al formato adecuado.
 */
- (int) writeBool: (BOOL) aValue;
- (BOOL) readBool;

/** 
 * Copia el valor de tipo datetime_t en el buffer transformado al formato adecuado.
 */
- (int) writeDateTime: (datetime_t) aValue;
- (datetime_t) readDateTime;

/** 
 * Copia el float en el buffer transformado al formato adecuado.
 */
- (int) writeFloat: (float) aValue;
- (float) readFloat; 

/** 
 * Copia el short en el buffer transformado al formato adecuado.
 */
- (int) writeMoney: (money_t) value;
- (money_t) readMoney; 


/**
 * Devuelve el tamanio en bytes de un registro de auditoria.
 * Cada subclase de InfoFormatter devuelve su valor correspondiente.
 */ 
- (int) getAuditSize;

/**
 * Formatea un registro de auditoria.
 * @buf (char *) se almacena la auditoria formateada en buf,
 * @result (int) devuelve el tamanio de los datos formateados.
 */
- (int) formatAudit: (char *) aBuffer audits: (ABSTRACT_RECORDSET) auditsRS changeLog: (ABSTRACT_RECORDSET) changeLogRS;

/**
 * Formatea un registro de deposito.
 * @buf (char *) se almacena el deposito formateada en buf,
 * @result (int) devuelve el tamanio de los datos formateados.
 */
- (int) formatDeposit: (char *) aBuffer
		includeDepositDetails: (BOOL) aIncludeDepositDetails
		deposits: (ABSTRACT_RECORDSET) aDepositRS
		depositDetails: (ABSTRACT_RECORDSET) aDepositDetailRS;


/**/
- (int) formatExtraction: (char *) aBuffer
		includeExtractionDetails: (BOOL) aIncludeExtractionDetails
		extractions: (ABSTRACT_RECORDSET) aExtractionRS
		extractionDetails: (ABSTRACT_RECORDSET) aExtractionDetailRS
		bagNumber: (char *) aBagNumber
		hasBagTracking: (BOOL) aHasBagTracking
		bagTrackingDetails: (ABSTRACT_RECORDSET) aBagTrackingDetailsRS;

/**
 * Formatea un registro de zclose.
 * @buf (char *) se almacena el zclose formateado en buf,
 * @result (int) devuelve el tamanio de los datos formateados.
 */
- (int) formatZClose: (char *) aBuffer
		includeZCloseDetails: (BOOL) aIncludeZCloseDetails
		zclose: (ABSTRACT_RECORDSET) aZCloseRS;

/**
 * Formatea un registro de xclose.
 * @buf (char *) se almacena el xclose formateado en buf,
 * @result (int) devuelve el tamanio de los datos formateados.
 */
- (int) formatXClose: (char *) aBuffer
		includeXCloseDetails: (BOOL) aIncludeXCloseDetails
		xclose: (ABSTRACT_RECORDSET) aXCloseRS;

/**
 * Formatea un usuario.
 * @buf (char *) se almacena el user formateado en buf,
 * @result (int) devuelve el tamanio de los datos formateados.
 */
- (int) formatUser: (char *) aBuffer
		user: (id) aUser;

@end

#endif
