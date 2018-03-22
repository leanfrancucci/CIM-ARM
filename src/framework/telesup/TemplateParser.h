#ifndef TEMPLATE_PARSER_H
#define TEMPLATE_PARSER_H

#define TEMPLATE_PARSER id

#include <Object.h>
#include "ctapp.h"
#include "StringTokenizer.h"

typedef struct {
  long fileSize;
	char fileName[100];
} TemplateDataFile;

/**
 *	Implementa el parsing de la plantilla de mensajes PTSD recibidos desde el CMP para 
 * inicializar el equipo
 */
@interface TemplateParser: Object
{
	id proxy;
	id parser;
	id formatter;
	char buffResult[100];
	COLLECTION filesList;
	BOOL canProccess;
	char templateName[100];
	id myObserver;
	int myCount;
	BOOL myIsEmptyTemplate;
	BOOL myIsInitBoxTemplate;
}

/**
 * Indica si un archivo existe o no
 */
- (BOOL) existFile: (char *) aFileName size: (long) aSize;

/**
 * Parsea el archivo
 */
- (void) parseTemplate;

/**
 * Procesa el mensaje PTSD recibido por parametro
 */
- (void) proccessPTSD: (char *) aMsg;

/**
 * Aplica el template
 */
- (void) applyTemplate: (id) anObserver;

/**
 * Indica si el equipo se encuentra en estado inicial para poder ejecutar el template
 */
- (BOOL) isInitialState;

/**
 * Indica si el template ya fue ejecutado. Si me dice que si es porque la aplicacion
 * del template habia terminado mal. Es decir con error.
 */
- (BOOL) wasExecuted;

/**
 * Borrar el archivo de estado inicial luego de aplicar el template o luego de
 * que el admin cambie su parssword.
 */
- (void) deleteInitialStateFile;

/**
 * Crea el archivo de estado inicial. Este metodo se utiliza al cambiar de estado
 * el equipo y pasar a bloqueo de fabrica.
 */
- (void) createInitialStateFile;

/**
 * Borrar el archivo que indica el comienzo de la aplicacion del template.
 */
- (void) deleteStartTemplateFile;

/**
 * Borrar el archivo de template
 */
- (void) deleteTemplateFile;

/**
 * Imprime reporte con el resultado de la aplicacion del template
 */
- (void) printReport;

/**
 * Imprime reporte con indicando que no se aplicó el template por un error detectado
 */
- (void) printErrorReport;

/**
 * Carga la lista con los nombres de los archivos a enviar por el CMP
 * Retorna TRUE o FALSE si pudo o no cargar la lista de archivos
 */
- (BOOL) loadFilesList;

/**
 * Devuelve la lista de archivos que el CMP me va a enviar
 */
- (COLLECTION) getFilesList;

/**
 * Setea si es ya posible procesar el template
 */
- (void) setCanProccessTemplate: (BOOL) aValue;

/**
 * Indica si es ya posible procesar el template
 */
- (BOOL) canProccessTemplate;

/**
 * Indica si el template esta vacio
 */
- (BOOL) isEmptyTemplate;

/**
 * Creo el archivo filesList.cmp pero solo con el nombre del archivo template
 */
- (void) createFilesListFile;

/**
 * Creo el archivo start.tpl para indicar que se comenzó la aplicacion del template
 */
- (void) createStartTemplateFile;

/**
 * Encripta un archivo
 */
- (void) encode: (char *) aFileName path: (char *) aPath;

/**
 * Desencripta un archivo
 */
- (void) decode: (char *) aFileName path: (char *) aPath;

/**
 * Desencripta el template
 */
- (void) decodeTemplate;

/**
 * Elimina los archivos involucrados
 */
- (void) abortProccess: (BOOL) aDelInitialFile delStartFile: (BOOL) aDelStartFile;

@end

#endif
