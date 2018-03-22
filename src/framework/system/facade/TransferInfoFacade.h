/*
 * GV : 07-03-2005: Los nombres de  los metodos 
 * 				getCallTrafficRecordSet, getCallTrafficRecordSetById,
 *				getCallTrafficRecordSetByDate y getCallAmountsRecordSet se cambiaron
 *				por getCallsTrafficRecordSet, getCallsTrafficRecordSetById,
 *				getCallsTrafficRecordSetByDate y getCallsAmountsRecordSet respectivamente.
 */


#ifndef TRANSFERINFOFACADE_H
#define TRANSFERINFOFACADE_H

#define TRANSFER_INFO_FACADE id
        
#include <Object.h>
#include "system/db/all.h"
#include "ctapp.h"

/**
 *	<<singleton>>
 * Clase que maneja la informacion a transferir del sistema.
 */

@interface TransferInfoFacade : Object
{
	char myFileName[255];
}

/**
 *
 */

+ new;
+ getInstance;
- initialize;


/**
 * AUDITORIAS **
 *
 */
- (ABSTRACT_RECORDSET) getAuditsRecordSet;

/**
 * Los valores limite del rango se incluyen en el rango de filtrado.
 */
- (ABSTRACT_RECORDSET) getAuditsRecordSetById: (unsigned long) aFromId to: (unsigned long) aToId;
 

/**
 * Los valores limite del rango se incluyen en el rango de filtrado.
 */
- (ABSTRACT_RECORDSET) getAuditsRecordSetByDate: (datetime_t) aFromDate to: (datetime_t) aToDate;



@end

#endif
