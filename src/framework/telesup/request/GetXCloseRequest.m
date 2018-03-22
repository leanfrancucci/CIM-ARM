#include "assert.h"
#include "GetXCloseRequest.h"
#include "system/util/all.h"
#include "Persistence.h"
#include "TransferInfoFacade.h"
#include "TelesupFacade.h"
#include "Audit.h"
#include "Persistence.h"
#include "ZCloseDAO.h"
#include "CommercialStateMgr.h"


// 1000 x close
#define MAX_XCLOSE_FILE_SIZE 45000

static GET_XCLOSE_REQUEST mySingleInstance = nil;
static GET_XCLOSE_REQUEST myRestoreSingleInstance = nil;

/**/
@implementation GetXCloseRequest

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
	[self setReqType: GET_XCLOSE_REQ];
	return self;
}

/**/
- (void) clearRequest
{
	[super clearRequest];
	myFilterType = NO_INFO_FILTER;
	myLastXCloseNumberTransfered = 0;
}

/**/
- (void) setFromDate: (datetime_t) aFromDate { myFromDate = aFromDate; }
- (void) setToDate: (datetime_t) aToDate { myToDate = aToDate; }

/**/
- (void) setFromXCloseNumber: (unsigned long) aFromNumber { myFromXCloseNumber = aFromNumber; }
- (void) setToXCloseNumber: (unsigned long) aToNumber { myToXCloseNumber = aToNumber; }

/**/
- (void) setFilterInfoType: (int) aFilterType { myFilterType = aFilterType; }

/**/
- (void) setIncludeXCloseDetails: (BOOL) aIncludeXCloseDetails { myIncludeXCloseDetails = aIncludeXCloseDetails; }

/**/
- (void) generateRequestDataFile
{
	ABSTRACT_RECORDSET xcloseRS = NULL;
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
	myIncludeXCloseDetails = TRUE;

	module = [[CommercialStateMgr getInstance] getModuleByCode: ModuleCode_SEND_END_OF_DAY];

	date = [module getBaseDateTime];
	moduleBaseDateTime = [SystemTime convertToLocalTime: date]; 

	date = [module getExpireDateTime];
	moduleExpireDateTime = [SystemTime convertToLocalTime: date]; 

	hoursQty = [module getHoursQty];

	switch (myFilterType) {
	
		case NO_INFO_FILTER:
			xcloseRS = [[[Persistence getInstance] getZCloseDAO] getNewZCloseRecordSet];
			break;
			
		case NOT_TRANSFER_INFO_FILTER:
			
      myLastXCloseNumberTransfered = [[TelesupFacade getInstance] getTelesupParamAsLong: "LastTelesupXCloseNumber"
																				telesupRol: myReqTelesupRol];

			xcloseRS = [[[Persistence getInstance] getZCloseDAO] getNewZCloseRecordSet];
			from = myLastXCloseNumberTransfered +1;
			break;
			
		case DATE_INFO_FILTER:
			xcloseRS = [[[Persistence getInstance] getZCloseDAO] getZCloseRecordSetByDate: myFromDate to: myToDate];			
			break;

    case NUMBER_INFO_FILTER:
			xcloseRS = [[[Persistence getInstance] getZCloseDAO] getNewZCloseRecordSet];				
			from = myFromXCloseNumber;
			break;			
		
		default:
			THROW( TSUP_INVALID_FILTER_EX );
			break;
	}

	// Verifica que el recordSet no este vacio.
	if (!xcloseRS) return;

	[xcloseRS open];
	[xcloseRS moveFirst];

	if (myFilterType == NOT_TRANSFER_INFO_FILTER) {

	//	doLog(0,"GetXCloseRequest -> Buscando XClose %ld\n", from);
		if (![[[Persistence getInstance] getZCloseDAO] findCashCloseById: xcloseRS value: from]) {
			[xcloseRS moveFirst];

			// si no hay datos o fromId >= al primer registro -> me voy
			if ( ([xcloseRS eof]) || (from >= [xcloseRS getLongValue: "NUMBER"]) ) {
				[xcloseRS close];
				[xcloseRS free];
				return;
			}
		}

	} else {

		if (myFilterType == NUMBER_INFO_FILTER) {
			//doLog(0,"GetXCloseRequest -> Buscando XClose %ld\n", from);
	
			if (![[[Persistence getInstance] getZCloseDAO] findCashCloseById: xcloseRS value: from]) {
				[xcloseRS close];
				[xcloseRS free];
				return;
			}
	
		} else {
			[xcloseRS moveFirst];
		}

	}
	
	TRY
		while (![xcloseRS eof]) {

		if ([xcloseRS getCharValue: "CLOSE_TYPE"] == CloseType_CASH_CLOSE) {
				// Verifica si ya me pase del numero de deposito hasta (solo para filtro por numero)
				if (myFilterType == NUMBER_INFO_FILTER && [xcloseRS getLongValue: "NUMBER"] > myToXCloseNumber) break;
	
				// verifica que el deposito se encuentre dentro del rango especificado en el modulo
			  // o que su expiraci�n sea infinita
			  /*if ( (([xcloseRS getDateTimeValue: "OPEN_TIME"] >= moduleBaseDateTime ) && 
					    ([xcloseRS getDateTimeValue: "OPEN_TIME"] <= moduleExpireDateTime)) || 
					   (([xcloseRS getDateTimeValue: "OPEN_TIME"] >= moduleBaseDateTime ) &&
						  (hoursQty == 0))
				   ) {*/

					myLastXCloseNumberTransfered = [xcloseRS getLongValue: "NUMBER" ];
		
					// Formateo el zclose
					n = [myInfoFormatter formatXClose: myBuffer
									includeXCloseDetails: myIncludeXCloseDetails
									xclose: xcloseRS];
		
					//doLog(0,"Escribiendo %d bytes del xclose %ld\n", n, myLastXCloseNumberTransfered);
		
					// Escribe el xclose
					if (n != 0) {
						if ([self writeToRequestDataFile: myBuffer size: n] <= 0)
							THROW( TSUP_GENERAL_EX );
					
						fileSize += n;			
		
						// si llego al maximo permitido corta
						if ([self reachMaxFileSize: fileSize maxFileSize: MAX_XCLOSE_FILE_SIZE]) 
							break;
					}
		
				//}

			}

			if (![xcloseRS moveNext]) break;

		}
	
	FINALLY

    [xcloseRS close];
    [xcloseRS free];
	
	END_TRY;

}

/**/
- (void) endRequestDataFile
{
	/* Configura el valor del ultimo deposito transferido */
	if (myFilterType == NOT_TRANSFER_INFO_FILTER) {

		  [[TelesupFacade getInstance] setTelesupParamAsLong: "LastTelesupXCloseNumber" value: myLastXCloseNumberTransfered telesupRol: myReqTelesupRol];
            
		  [[TelesupFacade getInstance] telesupApplyChanges: myReqTelesupRol];
		
	}
}


@end
