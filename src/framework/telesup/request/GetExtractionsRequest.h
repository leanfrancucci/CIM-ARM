#ifndef GET_EXTRACTIONS_REQUEST_H
#define GET_EXTRACTIONS_REQUEST_H

#define GET_EXTRACTIONS_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "GetDataFileRequest.h"


/**
 *	Obtiene las extracciones generados en el sistema
 */
@interface GetExtractionsRequest: GetDataFileRequest
{	
	char myBuffer[4096];
	unsigned long myLastExtractionNumberTransfered;
	int	myFilterType;
	datetime_t myFromDate;
	datetime_t myToDate;
	int myFromExtractionNumber;
	int myToExtractionNumber;
	BOOL myIncludeExtractionDetails;
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
- (void) setFromExtractionNumber: (unsigned long) aFromNumber;
- (void) setToExtractionNumber: (unsigned long) aToNumber;
			
@end

#endif

