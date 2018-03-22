#include "assert.h"
#include "GetZCloseRequest.h"
#include "system/util/all.h"
#include "Persistence.h"
#include "TransferInfoFacade.h"
#include "TelesupFacade.h"
#include "Audit.h"
#include "Persistence.h"
#include "ZCloseDAO.h"
#include "CommercialStateMgr.h"


// 1000 z close
#define MAX_ZCLOSE_FILE_SIZE 34000

static GET_ZCLOSE_REQUEST mySingleInstance = nil;
static GET_ZCLOSE_REQUEST myRestoreSingleInstance = nil;

/**/
@implementation GetZCloseRequest

/**/
+ getSingleVarInstance { return mySingleInstance; }
+ (void) setSingleVarInstance: (id) aSingleVarInstance { mySingleInstance =  aSingleVarInstance; }

/**/
+ getRestoreVarInstance { return myRestoreSingleInstance; }
+ (void) setRestoreVarInstance: (id) aRestoreVarInstance { myRestoreSingleInstance = aRestoreVarInstance; }

/**/
- initialize
{
	[super initialize];
	[self setReqType: GET_ZCLOSE_REQ];
	return self;
}

/**/
- (void) clearRequest
{
	[super clearRequest];
	myFilterType = NO_INFO_FILTER;
	myLastZCloseNumberTransfered = 0;
}

/**/
- (void) setFromDate: (datetime_t) aFromDate { myFromDate = aFromDate; }
- (void) setToDate: (datetime_t) aToDate { myToDate = aToDate; }

/**/
- (void) setFromZCloseNumber: (unsigned long) aFromNumber { myFromZCloseNumber = aFromNumber; }
- (void) setToZCloseNumber: (unsigned long) aToNumber { myToZCloseNumber = aToNumber; }

/**/
- (void) setFilterInfoType: (int) aFilterType { myFilterType = aFilterType; }

/**/
- (void) setIncludeZCloseDetails: (BOOL) aIncludeZCloseDetails { myIncludeZCloseDetails = aIncludeZCloseDetails; }

/**/
- (void) generateRequestDataFile
{
	ABSTRACT_RECORDSET zcloseRS = NULL;
	unsigned long from = 0;
	int n;
	unsigned long fileSize = 0;
	id module;
	datetime_t moduleBaseDateTime;
	datetime_t moduleExpireDateTime;
	datetime_t date;
	int hoursQty;

	assert(myInfoFormatter);

  // siempre le incluyo el detalle
	myIncludeZCloseDetails = TRUE;

	module = [[CommercialStateMgr getInstance] getModuleByCode: ModuleCode_SEND_END_OF_DAY];

	date = [module getBaseDateTime];
	moduleBaseDateTime = [SystemTime convertToLocalTime: date]; 

	date = [module getExpireDateTime];
	moduleExpireDateTime = [SystemTime convertToLocalTime: date]; 

  hoursQty = [module getHoursQty];

	switch (myFilterType) {
	
		case NO_INFO_FILTER:
			zcloseRS = [[[Persistence getInstance] getZCloseDAO] getNewZCloseRecordSet];
			break;
			
		case NOT_TRANSFER_INFO_FILTER:
			
      myLastZCloseNumberTransfered = [[TelesupFacade getInstance] getTelesupParamAsLong: "LastTelesupZCloseNumber"
																				telesupRol: myReqTelesupRol];

			zcloseRS = [[[Persistence getInstance] getZCloseDAO] getNewZCloseRecordSet];
			from = myLastZCloseNumberTransfered +1;
			break;
			
		case DATE_INFO_FILTER:
			zcloseRS = [[[Persistence getInstance] getZCloseDAO] getZCloseRecordSetByDate: myFromDate to: myToDate];
			break;

    case NUMBER_INFO_FILTER:
				zcloseRS = [[[Persistence getInstance] getZCloseDAO] getNewZCloseRecordSet];
				from = myFromZCloseNumber;
			break;			
		
		default:
			THROW( TSUP_INVALID_FILTER_EX );
			break;
	}

	// Verifica que el recordSet no este vacio.
	if (!zcloseRS) return;

	[zcloseRS open];
	[zcloseRS moveFirst];

	if (myFilterType == NOT_TRANSFER_INFO_FILTER) {

	//	doLog(0,"GetZCloseRequest -> Buscando ZClose %ld\n", from);
		if (![[[Persistence getInstance] getZCloseDAO] findZCloseById: zcloseRS value: from]) {
			[[[Persistence getInstance] getZCloseDAO] moveFirstZClose: zcloseRS];

			// si no hay datos o fromId >= al primer registro -> me voy
			if ( ([zcloseRS eof]) || (from >= [zcloseRS getLongValue: "NUMBER"]) ) {
				[zcloseRS close];
				[zcloseRS free];
				return;
			}
		}

	} else {

		if (myFilterType == NUMBER_INFO_FILTER) {
		//	doLog(0,"GetZCloseRequest -> Buscando ZClose %ld\n", from);

			if (![[[Persistence getInstance] getZCloseDAO] findZCloseById: zcloseRS value: from]) {
				[zcloseRS close];
				[zcloseRS free];
				return;
			}
	
		} else {
			[zcloseRS moveFirst];
		}

	}
	
	TRY

		while (![zcloseRS eof]) {

			if ([zcloseRS getCharValue: "CLOSE_TYPE"] == CloseType_END_OF_DAY) {

				// Verifica si ya me pase del numero de deposito hasta (solo para filtro por numero)
				if (myFilterType == NUMBER_INFO_FILTER && [zcloseRS getLongValue: "NUMBER"] > myToZCloseNumber) break;

				// verifica que el deposito se encuentre dentro del rango especificado en el modulo
			  // o que su expiracion sea infinita
			 /* if ( (([zcloseRS getDateTimeValue: "CLOSE_TIME"] >= moduleBaseDateTime ) && 
					    ([zcloseRS getDateTimeValue: "CLOSE_TIME"] <= moduleExpireDateTime)) || 
					   (([zcloseRS getDateTimeValue: "CLOSE_TIME"] >= moduleBaseDateTime ) &&
						  (hoursQty == 0))
				   ) {*/

					myLastZCloseNumberTransfered = [zcloseRS getLongValue: "NUMBER"];
		
					// Formateo el zclose
					n = [myInfoFormatter formatZClose: myBuffer
									includeZCloseDetails: myIncludeZCloseDetails
									zclose: zcloseRS];
		
					//doLog(0,"Escribiendo %d bytes del zclose %ld\n", n, myLastZCloseNumberTransfered);
		
					// Escribe el zclose
					if (n != 0) {
						if ([self writeToRequestDataFile: myBuffer size: n] <= 0)
							THROW( TSUP_GENERAL_EX );
					
						fileSize += n;			
	
						// si llego al maximo permitido corta
						if ([self reachMaxFileSize: fileSize maxFileSize: MAX_ZCLOSE_FILE_SIZE]) 
							break;
					}

				//}

			}

			if (![zcloseRS moveNext]) break;
			
		}
	
	FINALLY

    [zcloseRS close];
    [zcloseRS free];
	
	END_TRY;

}

/**/
- (void) endRequestDataFile
{
	/* Configura el valor del ultimo deposito transferido */
	if (myFilterType == NOT_TRANSFER_INFO_FILTER) {

		  [[TelesupFacade getInstance] setTelesupParamAsLong: "LastTelesupZCloseNumber" value: myLastZCloseNumberTransfered telesupRol: myReqTelesupRol];
            
		  [[TelesupFacade getInstance] telesupApplyChanges: myReqTelesupRol];
		
	}
}


@end
