#ifndef GET_DEPOSITS_REQUEST_H
#define GET_DEPOSITS_REQUEST_H

#define GET_DEPOSITS_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "GetDataFileRequest.h"


/**
 *	Obtiene los depositos generados en el sistema
 */
@interface GetDepositsRequest: GetDataFileRequest
{	
	char myBuffer[4096];
	unsigned long myLastDepositNumberTransfered;
	int	myFilterType;
	datetime_t myFromDate;
	datetime_t myToDate;
	int myFromDepositNumber;
	int myToDepositNumber;
  BOOL myIncludeDepositDetails;
}		
	

/**
 * Los metodos que especifican los parametros consultados
 */
/**/	
 
/**
 * Indica si el filtro seleccionado es por fecha, por id o sin filtro.
 * @param int filterType:	0: (NONE_INFO_FILTER) 	ningun filtro
 *							1: (ID_INFO_FILTER)		filtro por identificador de entidad
 *							2: (DATE_INFO_FILTER)	filtro por fecha
 */
- (void) setFilterInfoType: (int) aFilterInfoType;
- (void) setFromDate: (datetime_t) aFromDate;
- (void) setToDate: (datetime_t) aToDate;
- (void) setIncludeDepositDetails: (BOOL) aIncludeDepositDetails;
- (void) setFromDepositNumber: (unsigned long) aFromNumber;
- (void) setToDepositNumber: (unsigned long) aToNumber;
			
@end

#endif

