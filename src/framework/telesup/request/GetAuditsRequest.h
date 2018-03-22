#ifndef GET_AUDITS_H
#define GET_AUDITS_H

#define GET_AUDITS_REQUEST id

#include <Object.h>
#include "ctapp.h"
#include "GetDataFileRequest.h"
 

/**
 *	Transfiere auditorias
 */
@interface GetAuditsRequest: GetDataFileRequest
{	
	unsigned long myLastAuditIdTransfered;
	unsigned long myLastAlarmIdTransfered;
	unsigned long myNextLastAuditIdTransfered;
	unsigned long myNextLastAlarmIdTransfered;
	unsigned long myTransferFromId;

	int myTransferOnlyCritical;

	char 			myBuffer[7168];

	int				myFilterType;

	datetime_t  	myFromDate;
	datetime_t 		myToDate;
	
	int 			myFromId;
	int 			myToId;

	int 			myExecutionMode;
}		 

/**
 * Los metodos que especifican los parametros consultados
 */

/**
 * Indica si el filtro seleccionado es por fecha, por id o sin filtro.
 * @param int filterType:	0: (NONE_INFO_FILTER) 	ningun filtro
 *							1: (ID_INFO_FILTER)		filtro por identificador de entidad
 *							2: (DATE_INFO_FILTER)	filtro por fecha
 */
- (void) setFilterInfoType: (int) aFilterInfoType;

- (void) setFromDate: (datetime_t) aFromDate;
- (void) setToDate: (datetime_t) aToDate;

- (void) setFromId: (int) aFromId;
- (void) setToId: (int) aToId;

/**/
- (void) setTransferOnlyCritical: (BOOL) aValue;

/**
 * Setea quien se esta invocando al parser:
 * PIMS_TSUP_ID
 * CMP_TSUP_ID
 * CMP_REMOTE_TSUP_ID
 * STT_ID	
 */
- (void) setExecutionMode: (int) aValue;

@end


#endif



