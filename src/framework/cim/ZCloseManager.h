#ifndef ZCLOSE_MANAGER_H
#define ZCLOSE_MANAGER_H

#define ZCLOSE_MANAGER id

#include <Object.h>
#include "CimDefs.h"
#include "ZClose.h"
#include "Door.h"
#include "Deposit.h"

/**
 *	Encapsula el proceso de generar una cierre Z obtener los cierres Z
 *	actuales (valores en caja).
 *
 *	<<singleton>>
 */
@interface ZCloseManager : Object
{
	ZCLOSE myCurrentZClose;
	datetime_t myLastZCloseTime;
	unsigned long myLastZCloseNumber;
	unsigned long myLastCashCloseNumber;
	OTIMER myTimer;
	COLLECTION myCurrentCashCloses;
}

/**
 *  Devuelve la unica instancia posible de esta clase
 */
+ getInstance;

/**
 *	Genera el cierre Z.
 */
- (void) generateZClose: (BOOL) aPrintOperatorReports;

/**
 *	Devuelve el cierre Z actual (en curso).
 *	@return el cierre Z.
 */	
- (ZCLOSE) getCurrentZClose;

- (ZCLOSE) loadLastZClose;

/**
 *	Devuelve el cierre X actual (en curso).
 *	@return el cierre X.
 */
- (ZCLOSE) loadLastCashClose;

/**/
- (void) addNewCashClose: (CIM_CASH) aCimCash;

/*
 * Devuelve un determinado zclose
 */
- (ZCLOSE) loadZCloseById: (unsigned long) anId;

/**
 *
 */
- (void) generateCurrentZClose;

/**
 *
 */
- (void) generateCashReferenceSummary: (BOOL) detailReport reference: (CASH_REFERENCE) reference;

/**
 *
 */
- (void) generateUserReport: (USER) aUser includeDetail: (BOOL) aIncludeDetail;
- (void) generateUserReport: (USER) aUser includeDetail: (BOOL) aIncludeDetail resumeReport: (BOOL) aResumeReport viewHeader: (BOOL) aViewHeader viewFooter: (BOOL) aViewFooter;
- (BOOL) generateUserReports: (BOOL) aIncludeDetail;
- (BOOL) generateUserReports: (BOOL) aIncludeDetail resumeReport: (BOOL) aResumeReport;
- (BOOL) generateUserReports: (ZCLOSE) aZClose includeDetail: (BOOL) aIncludeDetail;
- (void) generateUserReport: (ZCLOSE) aZClose user: (USER) aUser includeDetail: (BOOL) aIncludeDetail resumeReport: (BOOL) aResumeReport viewHeader: (BOOL) aViewHeader viewFooter: (BOOL) aViewFooter;
- (BOOL) hasUserMovements: (USER) aUser;

/**
 *	Procesa el deposito pasado como parametro.
 *	El deposito se acumula en el Z actual.
 *	Es fundamental llamar a este metodo cada vez que se efectua un deposito para
 *	mantener sincronizados los valores en caja.
 *	@param deposit: el deposito efectuado.
 */
- (void) processDeposit: (DEPOSIT) aDeposit;

/**
 *	Procesa el detalle de un deposito pasado como parametro.
 *	El deposito se actumula en el Z actual
 *	Es fundamental llamar a este metodo cada vez que se recupera un deposito un deposito 
 *  el cual se almaceno por la mitad. Es decir se almaceno encabezado pero no todos los 
 *	detallespara, para mantener sincronizados los valores en caja.
 *	@param deposit: el deposito recuperado.
 *	@param depositDetail: el detalle del deposito recuperado.
 */
- (void) processTempDepositDetail: (DEPOSIT) aDeposit depositDetail: (DEPOSIT_DETAIL) aDepositDetail;

/**/
- (BOOL) inStartDay;

/**
 *  Devuelve TRUE si ya imprimio el cierre Z para el dia de hoy.
 */ 
- (BOOL) hasAlreadyPrintZClose;

/**
 * Retorna el ultimo numero de Z.
 */
- (unsigned long) getLastZNumber;

/*
 * Manda a imprimir el X.
 */
- (void) printCashClose: (ZCLOSE) aCashClose;

- (COLLECTION) loadCashCloses: (COLLECTION) aCimCashes
	fromCloseNumber: (unsigned long) aFromCloseNumber
	toCloseNumber: (unsigned long) aToCloseNumber;

/**/
- (void) loadAllCashes;

@end

#endif
