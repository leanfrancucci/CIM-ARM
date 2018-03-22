#include "assert.h"
#include "GetDepositsRequest.h"
#include "system/util/all.h"
#include "Persistence.h"
#include "TransferInfoFacade.h"
#include "TelesupFacade.h"
#include "Audit.h"
#include "Persistence.h"
#include "DepositDAO.h"
#include "CommercialStateMgr.h"

/* macro para debugging */
//#define LOG(args...) doLog(0,args)
//#define printd(args...)

// 1000 depositos 
#define MAX_DEPOSITS_FILE_SIZE 103000

static GET_DEPOSITS_REQUEST mySingleInstance = nil;
static GET_DEPOSITS_REQUEST myRestoreSingleInstance = nil;

/**/
@implementation GetDepositsRequest

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
	[self setReqType: GET_DEPOSITS_REQ];
	return self;
}

/**/
- (void) clearRequest
{
	[super clearRequest];
	myFilterType = NO_INFO_FILTER;
	myLastDepositNumberTransfered = 0;
}

/**/
- (void) setFromDate: (datetime_t) aFromDate { myFromDate = aFromDate; }
- (void) setToDate: (datetime_t) aToDate { myToDate = aToDate; }

/**/
- (void) setFromDepositNumber: (unsigned long) aFromDepositNumber { myFromDepositNumber = aFromDepositNumber; }
- (void) setToDepositNumber: (unsigned long) aToDepositNumber { myToDepositNumber = aToDepositNumber; }

/**/
- (void) setFilterInfoType: (int) aFilterType { myFilterType = aFilterType; }

/**/
- (void) setIncludeDepositDetails: (BOOL) aIncludeDepositDetails { myIncludeDepositDetails = aIncludeDepositDetails; }

/**/
- (void) generateRequestDataFile
{
	ABSTRACT_RECORDSET depositsRS = NULL;
	ABSTRACT_RECORDSET depositDetailsRS = NULL;
	unsigned long from = 0;
	int n;
	unsigned long fileSize = 0;
	id module;
	datetime_t moduleBaseDateTime;
	datetime_t moduleExpireDateTime;
	datetime_t date;
	int hoursQty;

	assert(myInfoFormatter);

	// Siempre incluyo el detalle ya que de otra forma
	// no tengo el importe de cada deposito ni la cantidad
	myIncludeDepositDetails = TRUE;

	module = [[CommercialStateMgr getInstance] getModuleByCode: ModuleCode_SEND_DROPS];

	date = [module getBaseDateTime];
	moduleBaseDateTime = [SystemTime convertToLocalTime: date];

	date = [module getExpireDateTime];
	moduleExpireDateTime = [SystemTime convertToLocalTime: date];

	hoursQty = [module getHoursQty];

	switch (myFilterType) {

		case NO_INFO_FILTER:
			depositsRS = [[[Persistence getInstance] getDepositDAO] getNewDepositRecordSet];
			break;

		case NOT_TRANSFER_INFO_FILTER:

      myLastDepositNumberTransfered = [[TelesupFacade getInstance] getTelesupParamAsLong: "LastTelesupDepositNumber"
																				telesupRol: myReqTelesupRol];

			depositsRS = [[[Persistence getInstance] getDepositDAO] getNewDepositRecordSet];
			from = myLastDepositNumberTransfered +1;
			break;

		case DATE_INFO_FILTER:
			depositsRS = [[[Persistence getInstance] getDepositDAO] getDepositRecordSetByDate: myFromDate to: myToDate];
			break;

    case NUMBER_INFO_FILTER:
				depositsRS = [[[Persistence getInstance] getDepositDAO] getNewDepositRecordSet];
				from = myFromDepositNumber;
			break;

		default:
			THROW( TSUP_INVALID_FILTER_EX );
			break;
	}

	// Verifica que el recordSet no este vacio.
	if (!depositsRS) return;

	[depositsRS open];
	[depositsRS moveFirst];

	/**/
	if (myFilterType == NOT_TRANSFER_INFO_FILTER) {

		//doLog(0,"GetDepositsRequest -> Buscando deposito %ld\n", from);
		if (![depositsRS findById: "NUMBER" value: from]) {
			[depositsRS moveFirst];

			// si no hay datos o fromId >= al primer registro -> me voy
			if ( ([depositsRS eof]) || (from >= [depositsRS getLongValue: "NUMBER"]) ) {
				[depositsRS close];
				[depositsRS free];
				return;
			}
		}

	} else {

		if (myFilterType == NUMBER_INFO_FILTER) {
		//	doLog(0,"GetDepositsRequest -> Buscando deposito %ld\n", from);
	
			[depositsRS findById: "NUMBER" value: from];
	
			if (([depositsRS eof]) || ([depositsRS getLongValue: "NUMBER"] < from)) {
				[depositsRS close];
				[depositsRS free];
				return;
			}
	
		} else {
			[depositsRS moveFirst];
		}

	}

	// Detalle del deposito
	depositDetailsRS = [[[Persistence getInstance] getDepositDAO] getNewDepositDetailRecordSet];
	[depositDetailsRS open];
	[depositDetailsRS moveFirst];

	TRY

		while (![depositsRS eof]) {

			// Verifica si ya me pase del numero de deposito hasta (solo para filtro por numero y para
			// los not transfer only para evitar que se envie un deposito que aun no se termino de almacenar)
			if ( (myFilterType == NUMBER_INFO_FILTER || myFilterType == NOT_TRANSFER_INFO_FILTER) && 
					 ([depositsRS getLongValue: "NUMBER"] > myToDepositNumber) ) break;

			//doLog(0," deposit number = %ld\n", [depositsRS getLongValue: "NUMBER"]);

			// verifica que el deposito se encuentre dentro del rango especificado en el modulo
			// o que su expiracion sea infinita
			/*if ( (([depositsRS getDateTimeValue: "OPEN_TIME"] >= moduleBaseDateTime ) && 
					  ([depositsRS getDateTimeValue: "OPEN_TIME"] <= moduleExpireDateTime)) || 
					 (([depositsRS getDateTimeValue: "OPEN_TIME"] >= moduleBaseDateTime ) &&
						(hoursQty == 0))
				 ) { */

				myLastDepositNumberTransfered = [depositsRS getLongValue: "NUMBER"];

				// Si incluye el detalle, me paro en el registro de detalle (si es que no estoy ahi ya)
				if ([depositDetailsRS eof] || [depositDetailsRS getLongValue: "NUMBER"] != myLastDepositNumberTransfered)
					[depositDetailsRS findFirstById: "NUMBER" value: myLastDepositNumberTransfered];

				// Formate el deposito
				n = [myInfoFormatter formatDeposit: myBuffer
								includeDepositDetails: myIncludeDepositDetails
								deposits: depositsRS
								depositDetails: depositDetailsRS];

				//doLog(0,"Escribiendo %d bytes del deposito %ld\n", n, myLastDepositNumberTransfered);

				// Escribe el deposito
				if (n != 0) {
					if ([self writeToRequestDataFile: myBuffer size: n] <= 0)
						THROW( TSUP_GENERAL_EX );

					fileSize += n;

					// si llego al maximo permitido corta
					if ([self reachMaxFileSize: fileSize maxFileSize: MAX_DEPOSITS_FILE_SIZE])
						break;
				}
		//	}

			if (![depositsRS moveNext]) break;
		}

	FINALLY

    [depositsRS close];
    [depositsRS free];

		[depositDetailsRS close];
		[depositDetailsRS free];

	END_TRY

}

/**/
- (void) endRequestDataFile
{

	/* Configura el valor del ultimo deposito transferido */
	if (myFilterType == NOT_TRANSFER_INFO_FILTER) {
		[[TelesupFacade getInstance] setTelesupParamAsLong: "LastTelesupDepositNumber" value: myLastDepositNumberTransfered telesupRol: myReqTelesupRol];
		[[TelesupFacade getInstance] telesupApplyChanges: myReqTelesupRol];
	}

}

@end
