#ifndef GET_XCLOSE_REQUEST_H
#define GET_XCLOSE_REQUEST_H

#define GET_XCLOSE_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "GetDataFileRequest.h"


/**
 *	Obtiene los depositos generados en el sistema
 */
@interface GetXCloseRequest: GetDataFileRequest
{	
	char myBuffer[4096];
	unsigned long myLastXCloseNumberTransfered;
	int	myFilterType;
	datetime_t myFromDate;
	datetime_t myToDate;
	int myFromXCloseNumber;
	int myToXCloseNumber;
  BOOL myIncludeXCloseDetails;
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
- (void) setIncludeXCloseDetails: (BOOL) aIncludeXCloseDetails;
- (void) setFromXCloseNumber: (unsigned long) aFromNumber;
- (void) setToXCloseNumber: (unsigned long) aToNumber;
			
@end

#endif

