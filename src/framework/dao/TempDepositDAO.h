#ifndef TEMP_DEPOSIT_DAO_H
#define TEMP_DEPOSIT_DAO_H

#define TEMP_DEPOSIT_DAO id

#include <Object.h>
#include "ctapp.h"
#include "system/db/all.h"
#include "DataObject.h"
#include "Deposit.h"

/** 
 *	Clase que maneja el la grabacion de depositos temporales con fines de recupero
 *	por corte de energia.
 *	Basicamente guarda por anticipado los depositos a medida que se van efectuando
 *	en una tabla llamada "temp_deposits"
 *	y el detalle en una tabla llamada "temp_deposit_details".
 *	Si ocurre un corte de energia, cuando se recupera verifica los datos de estos
 *	archivos y los corrobora contra los datos guardados en las tablas reales.
 *
 *	<<singleton>>
 */
@interface TempDepositDAO: DataObject
{
	COLLECTION myTempDeposits;
	OMUTEX myMutex;
}

/**/
+ getInstance;

/**/
- (void) saveDepositDetail: (DEPOSIT) aDeposit detail: (DEPOSIT_DETAIL) aDepositDetail;

/**/
- (void) updateDeposit: (DEPOSIT) aDeposit;

/**/
- (void) clearDeposit: (DEPOSIT) aDeposit;

/**/
- (id) loadLastByCimCash: (CIM_CASH) aCimCash;

@end

#endif
