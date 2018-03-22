#ifndef EXTRACTION_MANAGER_H
#define EXTRACTION_MANAGER_H

#define EXTRACTION_MANAGER id

#include <Object.h>
#include "CimDefs.h"
#include "Extraction.h"
#include "Door.h"
#include "Deposit.h"

/**
 *	Encapsula el proceso de generar una extraccion y obtener las extracciones
 *	actuales (valores en caja).
 *
 *	<<singleton>>
 */
@interface ExtractionManager : Object
{
	COLLECTION myCurrentExtractions;
	unsigned long myLastExtractionNumber;
	BOOL myIsGeneratingExtraction;
}

/**
 *  Devuelve la unica instancia posible de esta clase
 */
+ getInstance;

/**
 *	Genera la extraccion de la puerta pasada como parametro.
 *	La extraccion acumulada para esa puerta es grabada e impresa (y se abre una nueva)
 *	@param door: la puerta para la cual se quiere generar la extraccion.
 */
- (unsigned long) generateExtraction: (DOOR) aDoor user1: (USER) aUser1 user2: (USER) aUser2 bagNumber: (char*) aBagNumber bagTrackingMode: (int) aBagTrackingMode;


/**
 *	Devuelve la extraccion (valores actuales) para la puerta pasada como parametro.
 *	@param door: la puerta para la cual se quiere obtener los valores actuales.
 *	@return la extraccion (valores actuales).
 */	
- (EXTRACTION) getCurrentExtraction: (DOOR) aDoor;

/**/
- (COLLECTION) getCurrentExtractions;

/**
 *	Procesa el deposito pasado como parametro.
 *	El deposito se actumula a la extraccion actual que corresponda (segun la puerta)
 *	Es fundamental llamar a este metodo cada vez que se efectua un deposito para
 *	mantener sincronizados los valores en caja.
 *	@param deposit: el deposito efectuado.
 */
- (void) processDeposit: (DEPOSIT) aDeposit;

/**
 *	Procesa el detalle de un deposito pasado como parametro.
 *	El deposito se actumula a la extraccion actual que corresponda (segun la puerta)
 *	Es fundamental llamar a este metodo cada vez que se recupera un deposito un deposito 
 *  el cual se almaceno por la mitad. Es decir se almaceno encabezado pero no todos los 
 *	detallespara, para mantener sincronizados los valores en caja.
 *	@param deposit: el deposito recuperado.
 *	@param depositDetail: el detalle de deposito recuperado.
 */
- (void) processTempDepositDetail: (DEPOSIT) aDeposit depositDetail: (DEPOSIT_DETAIL) aDepositDetail;

/**
 *	Vuelve a cargar las extracciones, no deberia utilizarse comunemente ya que
 *	es llamado internamente al iniciar el sistema.
 */
- (void) loadExtractions;


/**
 * Retorna el ultimo numero de extraccion.
 */
- (unsigned long) getLastExtractionNumber;

/**/
- (EXTRACTION) loadById: (unsigned long) anId;

/**/
- (void) storeBagTrackingCollection: (COLLECTION) aCollection bagTrackingMode: (int) aBagTrackingMode;

/**/
- (BOOL) isGeneratingExtraction;

/**/
- (void) addCurrentCashClose: (ZCLOSE) aCashClose;

@end

#endif
