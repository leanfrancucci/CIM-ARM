#ifndef ACCEPTOR_DAO_H
#define ACCEPTOR_DAO_H

#define ACCEPTOR_DAO id

#include <Object.h>
#include "DataObject.h"
#include "system/util/all.h"
#include "Denomination.h"

/**
 *	Implementacion de la persistencia de la configuracion de aceptadores (validadores/buzones).
 *
 *	<<singleton>>
 */
@interface AcceptorDAO : DataObject
{
	ABSTRACT_RECORDSET myAcceptorsRS;
	ABSTRACT_RECORDSET myAcceptedDepositValuesRS;
	ABSTRACT_RECORDSET myCurrencyByDepValueRS;
	ABSTRACT_RECORDSET denominationsRS;
}

+ getInstance;
- (COLLECTION) loadAll: (COLLECTION) aDoorCollection;

- (void) storeDenomination: (int) aDepositValueType acceptorId: (int) anAcceptorId currencyId: (int) aCurrencyId denomination: (DENOMINATION) aDenomination;

- (void) deleteDenomination: (int) aDepositValueType acceptorId: (int) anAcceptorId currencyId: (int) aCurrencyId denomination: (DENOMINATION) aDenomination;

/**/
- (void) addDepositValueType: (int) anAcceptorId depositValueType: (int) aDepositValueType;
- (void) removeDepositValueType: (int) anAcceptorId depositValueType: (int) aDepositValueType;

/**/
- (void) addDepositValueTypeCurrency: (int) anAcceptorId depositValueType: (int) aDepositValueType currencyId: (int) aCurrencyId;
- (void) removeDepositValueTypeCurrency: (int) anAcceptorId depositValueType: (int) aDepositValueType currencyId: (int) aCurrencyId;


@end

#endif
