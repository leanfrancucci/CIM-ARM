#ifndef G2TELESUPPARSER_H
#define G2TELESUPPARSER_H

#define G2_TELESUP_PARSER id

#include <Object.h>
#include "ctapp.h"
#include "StringTokenizer.h"

#include "G2TelesupDefs.h"
#include "TelesupParser.h"

#include "GenericGetRequest.h"
#include "GenericSetRequest.h"


/**
 *	Implementa el parsing de los mensajes provenientes
 *  de la telesupervisi� con el sistema G2
 */
@interface G2TelesupParser: TelesupParser
{
	int 					myErrorCode;	
	STRING_TOKENIZER		myTokenizer;
	char					myTokenBuffer[TELESUP_MSGLINE_SIZE + 1];	
	char					myRequestName[TELESUP_REQUEST_NAME_SIZE + 1];
	char					paramNameBuffer[TELESUP_MSGLINE_SIZE + 1];
	char					paramValueBuffer[TELESUP_MSGLINE_SIZE + 1];
	char					myAuxBuffer[TELESUP_MSGLINE_SIZE + 1 ];
	int 					myExecutionMode;
	id myViewer;
    id myEventsProxy;
    id mySystemOpRequest;

}

/**
 * Metodos Privados
 **/


/** 
 * Devuelve el Request adecuado y lo configura con los datos apropiados. 
 * Para agregar un nuevo Request se debe agregar un case al switch de este metodo.
 * (se usa el metodo para aislar el switch/case)
 * @param int reqType especifica el subtipo de Request que debe crear. 
 * @msg  char * es el mensaje en donde se extraen los datos para configurar el Request. 
 */
- (REQUEST) getRequestFromType: (int) aReqType operation: (ENTITY_REQUEST_OPS) aReqOp msg: (char *)aMessage;

/**
 * Devuelve el nombre del Reuqest sin espacios al inicio ni al final y sin \n
 */
- (char *) getRequestName: (char *) aMessage;

/**
 *  Devuelve el tipo de Request especifico en base al nombre 
 *	del request recibido
 * Devuelve el INVALID_REQ si no se encontro el request asociado.
 */
- (int) getRequestType: (char *) aRequestName;

/**
 * Devuelve un identificador numerico unico por cada Request que 
 * identifica el tipo de accion que se debe ejecutar enb el 
 * procesamiento del Request.
 * Devuelve el 0 si se produjo un error (no deberia producirse un error)
 */
- (ENTITY_REQUEST_OPS) getRequestOperation: (char *) aRequestName;

/**
 * Devuelve TRUE si el request puede ser recibido dentro de un job.
 * Devuelve FALSE en caso contrario.
 */
- (BOOL) isJobableRequest: (char *) aRequestName;

/**
 * Devuelve TRUE si el mensaje tiene el modificador "All\n" y 
 * FALSE en caso contrario.
 */
- (BOOL) hasAllModifier: (char *) aMessage;

/**
 * Devuelve TRUE si aParamName esta incluido en aBuffer  *
 * La cadena aBuffer viene sin espacios inciales pero puede venir con espacios finales
 *
 */
- (BOOL) isEqualsParamName: (char *) aBuffer to: (char *) aParamName;

/**
 * Metodos Publicos
 **/
 
/**
 * Devuelve TRUE si ParamName esta contenido en aMessage en base
 * al formato de mensaje PTSD: ParamName = xxxx\n
 */
- (BOOL) isValidParam: (char *) aMessage name: (char *) aParamName;

/**
 * Devuelve TRUE si aModifier esta contenido en aMessage  
 */
- (BOOL) isValidModif: (char *) aMessage name: (char *) aModifier;

/**
 * Chequea la existencia de todos los parametros en paramList.
 * Si alguno no existe en el mensaje entonces lanza la excepcion TSUP_PARAM_NOT_FOUND_EX.
 * @param (char *) aMessage el mensaje en donde se buscan los parametros.
 * @param (char **) La lista de parametros (cadenas de caracteres) a buscar.
 * @param (int) la cantidad de parametros que se deben buscar (el tamanio de paramList)
 * @throws TSUP_PARAM_NOT_FOUND_EX
 */
- (void) checkForAllParams: (char *) aMessage paramList: (char **) aParamList paramCount: (int) aParamCount;

/**
 * Chequea la existencia de alguno de los parametros en paramList.
 * Si no existe ninguno en el mensaje entonces lanza la excepcion TSUP_PARAM_NOT_FOUND_EX.
 * @param (char *) aMessage el mensaje en donde se buscan los parametros.
 * @param (char **) La lista de parametros (cadenas de caracteres) a buscar.
 * @param (int) la cantidad de parametros que se deben buscar (el tamanio de paramList)
 * @throws TSUP_PARAM_NOT_FOUND_EX
 */
- (void) checkForAnyParams: (char *) aMessage paramList: (char **) aParamList paramCount: (int) aParamCount;

/**
 * Cheque que encuentre al menos uno de los modificadores en aModifList o el modificador "All"
 */	
- (void) checkForAllAndAnyModifs: (char *) aMessage paramList: (char **) aModifList 
																		paramCount: (int) aModifCount;

/**
 * Devuelve un nombre de archivo por defecto que es configurado a los Request de transferecnia de archivos.
 * El metodo no es reentrante.la señal 
 * @result (char *) un nombre de archivo por defecto con el formato "EqupmentId.YYYYmmddHHMMSS"
 */
- (char *) getDefaultFileName: (char *) ext;


/**** 
 ** Metodos publicos
 */
 
 
/**
 * Devuelve el valor correspondiente al parametro.
 * Devuelve la cadena que esta luego del igual en la linea
 *     ParamName=cadena\n
 *  El valor retornado es un puntero a paramValueBuffer que es donde se copia la cadena encontrada. 
 * 
 *- (char *) getParamAsString: (char *) aMessage paramName: (char *) aParamName;
 */
 
/**
 * Devuelve el valor correspondiente al parametro.
 * Devuelve el entero xxx en la cadena
 *     ParamName=xxx\n
 *
 * - (int) getParamAsInteger: (char *) aMessage paramName: (char *) aParamName;
 */
 
/**
 * Devuelve el valor correspondiente al parametro.
 * Devuelve el long xxx en la cadena
 *     ParamName=xxx\n
 *
 * - (int) getParamAsLong: (char *) aMessage paramName: (char *) aParamName;
 */
 
/**
 * Devuelve el valor correspondiente al parametro.
 * Devuelve el booleano xxx en la cadena
 *     ParamName=xxx\n
 *
 * - (BOOL) getParamAsBoolean: (char *) aMessage paramName: (char *) aParamName;
 */


/**
 * Devuelve el valor correspondiente al parametro.
 * Devuelve el double xxx en la cadena
 *     ParamName=xxx.xx\n
 *
 * - (float) getParamAsFloat: (char *) aMessage paramName: (char *) aParamName;
 */

/**
 * Devuelve el valor correspondiente al parametro.
 * Devuelve el money viene en formato xxx.xx
 *
 *
 * - (money_t) getParamAsCurrency: (char *) aMessage paramName: (char *) aParamName;
 */

/**
 * Devuelve el valor correspondiente al parametro en formato time_t
 * El valor viene como cadena ascii en formato ISO8601
 *
 * - (datetime_t) getParamAsDateTime: (char *) aMessage paramName: (char *) aParamName;	
 */

/**/
- (void) setViewer: (id) aViewer;

/**
 * Setea quien se esta invocando al parser:
 * PIMS_TSUP_ID
 * CMP_TSUP_ID
 * CMP_REMOTE_TSUP_ID
 * STT_ID	
 */
- (void) setExecutionMode: (int) aValue;

/**/
- (void) setEventsProxy: (id) anEventsProxy;
- (id) getEventsProxy;


@end

#endif
