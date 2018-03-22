#ifndef GET_ZCLOSE_REQUEST_H
#define GET_ZCLOSE_REQUEST_H

#define GET_ZCLOSE_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "GetDataFileRequest.h"


/**
 *	Obtiene los depositos generados en el sistema
 */
@interface GetZCloseRequest: GetDataFileRequest
{	
	char myBuffer[4096];
	unsigned long myLastZCloseNumberTransfered;
	int	myFilterType;
	datetime_t myFromDate;
	datetime_t myToDate;
	int myFromZCloseNumber;
	int myToZCloseNumber;
  BOOL myIncludeZCloseDetails;
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
- (void) setIncludeZCloseDetails: (BOOL) aIncludeZCloseDetails;
- (void) setFromZCloseNumber: (unsigned long) aFromNumber;
- (void) setToZCloseNumber: (unsigned long) aToNumber;
			
@end

#endif

