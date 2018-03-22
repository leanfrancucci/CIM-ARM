#include "assert.h"
#include "GetExtractionsRequest.h"
#include "system/util/all.h"
#include "Persistence.h"
#include "TransferInfoFacade.h"
#include "TelesupFacade.h"
#include "Audit.h"
#include "Persistence.h"
#include "ExtractionDAO.h"
#include "CommercialStateMgr.h"
#include "RegionalSettings.h"



// 1000 extracciones aprox.
#define MAX_EXTRACTIONS_FILE_SIZE 200000

static GET_EXTRACTIONS_REQUEST mySingleInstance = nil;
static GET_EXTRACTIONS_REQUEST myRestoreSingleInstance = nil;

/**/
@implementation GetExtractionsRequest

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
	[self setReqType: GET_EXTRACTIONS_REQ];
	return self;
}

/**/
- (void) clearRequest
{
	[super clearRequest];
	myFilterType = NO_INFO_FILTER;
	myLastExtractionNumberTransfered = 0;
}

/**/
- (void) setFromDate: (datetime_t) aFromDate { myFromDate = aFromDate; }
- (void) setToDate: (datetime_t) aToDate { myToDate = aToDate; }

/**/
- (void) setFromExtractionNumber: (unsigned long) aFromNumber { myFromExtractionNumber = aFromNumber; }
- (void) setToExtractionNumber: (unsigned long) aToNumber { myToExtractionNumber = aToNumber; }

/**/
- (void) setFilterInfoType: (int) aFilterType { myFilterType = aFilterType; }

/**/
- (void) generateRequestDataFile
{
	ABSTRACT_RECORDSET extractionsRS = NULL;
	ABSTRACT_RECORDSET extractionDetailsRS = NULL;
	ABSTRACT_RECORDSET bagTrackingDetailsRS = NULL;
	unsigned long from = 0;
	int n;
	unsigned long fileSize = 0;
	id module;
	datetime_t moduleBaseDateTime;
	datetime_t moduleExpireDateTime;
	datetime_t date;
	char bagNumber[50];
	char buffer[51];
	BOOL hasBagTracking;
	int hoursQty;

	assert(myInfoFormatter);

	// Siempre incluyo el detalle
	myIncludeExtractionDetails = TRUE;

	module = [[CommercialStateMgr getInstance] getModuleByCode: ModuleCode_SEND_EXTRACTIONS];

	date = [module getBaseDateTime];
	moduleBaseDateTime = [SystemTime convertToLocalTime: date];

	date = [module getExpireDateTime];
	moduleExpireDateTime = [SystemTime convertToLocalTime: date];

  hoursQty = [module getHoursQty];

	switch (myFilterType) {
	
		case NO_INFO_FILTER:
			extractionsRS = [[[Persistence getInstance] getExtractionDAO] getNewExtractionRecordSet];
			break;
			
		case NOT_TRANSFER_INFO_FILTER:
			
      myLastExtractionNumberTransfered = [[TelesupFacade getInstance] getTelesupParamAsLong: "LastTelesupExtractionNumber"
																				telesupRol: myReqTelesupRol];

	//		doLog(0,"lastExtraction = %ld\n", myLastExtractionNumberTransfered);
			extractionsRS = [[[Persistence getInstance] getExtractionDAO] getNewExtractionRecordSet];
			from = myLastExtractionNumberTransfered +1;
			break;
			
		case DATE_INFO_FILTER:
			extractionsRS = [[[Persistence getInstance] getExtractionDAO] getExtractionRecordSetByDate: myFromDate to: myToDate];
			break;

    case NUMBER_INFO_FILTER:
			extractionsRS = [[[Persistence getInstance] getExtractionDAO] getNewExtractionRecordSet];
			from = myFromExtractionNumber;
			break;			
		
		default:
			THROW( TSUP_INVALID_FILTER_EX );
			break;
	}

	// Verifica que el recordSet no este vacio.
	if (!extractionsRS) return;

	[extractionsRS open];
	[extractionsRS moveFirst];

	if (myFilterType == NOT_TRANSFER_INFO_FILTER) {

	//	doLog(0,"GetExtractionsRequest -> Buscando retiro %ld\n", from);
		if (![extractionsRS findById: "NUMBER" value: from]) {
			[extractionsRS moveFirst];

			// si no hay datos o fromId >= al primer registro -> me voy
			if ( ([extractionsRS eof]) || (from >= [extractionsRS getLongValue: "NUMBER"]) ) {
				[extractionsRS close];
				[extractionsRS free];
				return;
			}
		}

	} else {

		if (myFilterType == NUMBER_INFO_FILTER) {
		//	doLog(0,"GetExtractionsRequest -> Buscando retiro %ld\n", from);
	
			[extractionsRS findById: "NUMBER" value: from];
	
			if (([extractionsRS eof]) || ([extractionsRS getLongValue: "NUMBER"] < from)) {
				[extractionsRS close];
				[extractionsRS free];
				return;
			}
	
		} else {
			[extractionsRS moveFirst];
		}

	}

	extractionDetailsRS = [[[Persistence getInstance] getExtractionDAO] getNewExtractionDetailRecordSet];
	[extractionDetailsRS open];
	[extractionDetailsRS moveFirst];
	
	bagTrackingDetailsRS = [[[Persistence getInstance] getExtractionDAO] getNewBagTrackingRecordSet];
	[bagTrackingDetailsRS open];

	TRY

		while (![extractionsRS eof]) {

			// Verifica si ya me pase del numero de extraccion hasta (solo para filtro por numero y para
			// los not transfer only para evitar que se envie una extraccion que aun no se termino de almacenar)
			if ( (myFilterType == NUMBER_INFO_FILTER || myFilterType == NOT_TRANSFER_INFO_FILTER) && 
					 ([extractionsRS getLongValue: "NUMBER"] > myToExtractionNumber) ) break;

			date = [extractionsRS getDateTimeValue: "DATE_TIME"];

			// verifica que el deposito se encuentre dentro del rango especificado en el modulo
			// o que su expiracion sea infinita
			/*if ( (([extractionsRS getDateTimeValue: "DATE_TIME"] >= moduleBaseDateTime ) && 
					  ([extractionsRS getDateTimeValue: "DATE_TIME"] <= moduleExpireDateTime)) || 
					 (([extractionsRS getDateTimeValue: "DATE_TIME"] >= moduleBaseDateTime ) &&
						(hoursQty == 0))
				 ) {*/

				myLastExtractionNumberTransfered = [extractionsRS getLongValue: "NUMBER"];
	
				// Si incluye el detalle, me paro en el registro de detalle (si es que no estoy ahi ya)
				if ([extractionDetailsRS eof] || [extractionDetailsRS getLongValue: "NUMBER"] != myLastExtractionNumberTransfered)
					[extractionDetailsRS findFirstById: "NUMBER" value: myLastExtractionNumberTransfered];
	
				// me paro en el primer bag tracking el cual indica el numero de bolsa
				strcpy(bagNumber,"");
				hasBagTracking = FALSE;
				if ([bagTrackingDetailsRS moveLast]) {
					while (![bagTrackingDetailsRS bof] && ([bagTrackingDetailsRS getLongValue: "EXTRACTION_NUMBER"] != myLastExtractionNumberTransfered)) [bagTrackingDetailsRS movePrev];
				
					while (![bagTrackingDetailsRS bof] && ([bagTrackingDetailsRS getLongValue: "EXTRACTION_NUMBER"] == myLastExtractionNumberTransfered)) [bagTrackingDetailsRS movePrev];

					[bagTrackingDetailsRS moveNext];

					if ( (![bagTrackingDetailsRS bof]) && (![bagTrackingDetailsRS eof]) && [bagTrackingDetailsRS getLongValue: "PARENT_ID"] == 0) {
						hasBagTracking = TRUE;
						strcpy(bagNumber, [bagTrackingDetailsRS getStringValue: "NUMBER" buffer: buffer]);
					}
				}

				n = [myInfoFormatter formatExtraction: myBuffer
								includeExtractionDetails: myIncludeExtractionDetails
								extractions: extractionsRS
								extractionDetails: extractionDetailsRS
								bagNumber: bagNumber
								hasBagTracking: hasBagTracking
								bagTrackingDetails: bagTrackingDetailsRS];

					//doLog(0,"Escribiendo %d bytes del retiro %ld\n", n, myLastExtractionNumberTransfered);
	
				// Escribe la extraccion
				if (n != 0) {
					if ([self writeToRequestDataFile: myBuffer size: n] <= 0)
						THROW( TSUP_GENERAL_EX );
	
					fileSize += n;			
	
					// si llego al maximo permitido corta
					if ([self reachMaxFileSize: fileSize maxFileSize: MAX_EXTRACTIONS_FILE_SIZE]) 
						break;
				}
			//} 

			if (![extractionsRS moveNext]) break;

		}
	
	FINALLY

    [extractionsRS close];
    [extractionsRS free];
	
		[extractionDetailsRS close];
		[extractionDetailsRS free];

		[bagTrackingDetailsRS close];
		[bagTrackingDetailsRS free];
	
	END_TRY;
}

/**/
- (void) endRequestDataFile
{
	if (myFilterType == NOT_TRANSFER_INFO_FILTER) {

		  [[TelesupFacade getInstance] setTelesupParamAsLong: "LastTelesupExtractionNumber" value: myLastExtractionNumberTransfered telesupRol: myReqTelesupRol];
            
		[[TelesupFacade getInstance] telesupApplyChanges: myReqTelesupRol];
		
	}
}


@end
