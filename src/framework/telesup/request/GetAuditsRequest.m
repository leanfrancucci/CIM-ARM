#include "GetAuditsRequest.h"
#include "assert.h"
#include "system/util/all.h"
#include "Persistence.h"
#include "TelesupFacade.h"
#include "TransferInfoFacade.h"
#include "AuditDAO.h"
#include "EventManager.h"
#include "CommercialStateMgr.h"

// 1000 auditorias (36 auditoria 92 log)
#define MAX_AUDITS_FILE_SIZE 128000

/* macro para debugging */
//#define printd(args...) doLog(0,args)
#define printd(args...)

static GET_AUDITS_REQUEST mySingleInstance = nil;
static GET_AUDITS_REQUEST myRestoreSingleInstance = nil;

/**/
@implementation GetAuditsRequest		

- (BOOL) isCriticalAudit: (unsigned long) anEventId;

/**/
+ getSingleVarInstance
{
	 return mySingleInstance; 
}

+ (void) setSingleVarInstance: (id) aSingleVarInstance
{
	 mySingleInstance =  aSingleVarInstance;
}

/**/
+ getRestoreVarInstance 
{
	 return myRestoreSingleInstance; 
}

+ (void) setRestoreVarInstance: (id) aRestoreVarInstance
{
	 myRestoreSingleInstance = aRestoreVarInstance; 
}

/**/
- initialize
{
	[super initialize];
	myTransferOnlyCritical = FALSE;
	[self setReqType: GET_AUDITS_REQ];
	return self;
}

/**/

- (void) clearRequest
{
	[super clearRequest];
		
	myFilterType = NO_INFO_FILTER;
	myLastAuditIdTransfered = 0;
}

/**/
- (void) setFromDate: (datetime_t) aFromDate { myFromDate = aFromDate; }
- (void) setToDate: (datetime_t) aToDate { myToDate = aToDate; }
- (void) setFromId: (int) aFromId { myFromId = aFromId; }
- (void) setToId: (int) aToId { myToId = aToId; }
- (void) setFilterInfoType: (int) aFilterType { myFilterType = aFilterType; }


/**/
- (void) generateRequestDataFile
{
	TRANSFER_INFO_FACADE transferf = [TransferInfoFacade getInstance];	
	ABSTRACT_RECORDSET auditsRS = NULL;
	ABSTRACT_RECORDSET changeLogRS = NULL;
	int n;
	BOOL formatRecord = FALSE;
	unsigned long fileSize = 0;
	id module;
	datetime_t moduleBaseDateTime;
	datetime_t moduleExpireDateTime;
	datetime_t date;
	int hoursQty;
	
	assert(myInfoFormatter);

	/* Obtiene los recordsets */
	switch (myFilterType) {

		
		case NO_INFO_FILTER:
	
			auditsRS = [transferf getAuditsRecordSet];
			break;	

		
		case NOT_TRANSFER_INFO_FILTER:

			myLastAlarmIdTransfered = [[TelesupFacade getInstance] getTelesupParamAsLong: "LastTelesupAlarmId" 
																		telesupRol: myReqTelesupRol];

			myLastAuditIdTransfered = [[TelesupFacade getInstance] getTelesupParamAsLong: "LastTelesupAuditId" 
																		telesupRol: myReqTelesupRol];
			
		//	doLog(0,"myLastAuditIdTransfered = %ld\n", myLastAuditIdTransfered);
		//	doLog(0,"myLastAlarmIdTransfered = %ld\n", myLastAlarmIdTransfered);

			myNextLastAuditIdTransfered = myLastAuditIdTransfered;
	    myNextLastAlarmIdTransfered = myLastAlarmIdTransfered;

			if (myTransferOnlyCritical) {
				myLastAlarmIdTransfered++;
				myTransferFromId = myLastAlarmIdTransfered;
			} else {
					if (myLastAuditIdTransfered < myLastAlarmIdTransfered) {
						myLastAuditIdTransfered++;
						myTransferFromId = myLastAuditIdTransfered;
					} else {
						myLastAlarmIdTransfered++;
						myTransferFromId = myLastAlarmIdTransfered;
					}
			}
			
			myFromId = myTransferFromId;
			
		//	doLog(0,"myFromId = %ld\n", myFromId);
			auditsRS = [transferf getAuditsRecordSetById: myFromId to: 0];
			break;

		case ID_INFO_FILTER:
			auditsRS = [transferf getAuditsRecordSetById: myFromId to: myToId];
			break;		

		case DATE_INFO_FILTER:
			auditsRS = [transferf getAuditsRecordSetByDate: myFromDate to: myToDate];
			break;		

		default:
			THROW( TSUP_INVALID_FILTER_EX );
			break;
	}	

	/* Transformar los datos */
	if (!auditsRS) return;

	[auditsRS open];
	if (myFilterType != DATE_INFO_FILTER)
		[auditsRS moveBeforeFirst];
  else 
    [auditsRS moveFirst];

	/**/
	if (myFilterType == NOT_TRANSFER_INFO_FILTER) {

		if (![auditsRS findById: "AUDIT_ID" value: myFromId]) {
			[auditsRS moveFirst];

			// si no hay datos o fromId >= al primer registro -> me voy
			if ( ([auditsRS eof]) || (myFromId >= [auditsRS getLongValue: "AUDIT_ID"]) ) {
				[auditsRS close];
				[auditsRS free];
				return;
			}
		}

	} else {

		if (myFilterType == ID_INFO_FILTER || myFilterType == NO_INFO_FILTER) {
			if ((![auditsRS findFirstFromId: "AUDIT_ID" value: myFromId]) || ((myFilterType == ID_INFO_FILTER) && ([auditsRS getLongValue: "AUDIT_ID"] > myToId))) {
			//	doLog(0,"no hay nada para enviar \n");
				[auditsRS close];
				[auditsRS free];
				return;
			}
			//doLog(0,"comienza a enviar con el id = %ld\n", [auditsRS getLongValue: "AUDIT_ID"]);
		}

	}
			
	changeLogRS = [[[Persistence getInstance] getAuditDAO] getNewChangeLogRecordSet];
	[changeLogRS open];
	[changeLogRS moveFirst];
			
	TRY	

		// si solo transfiere las alarmas se basa en el rango de alarmas
		// si es auditorias se basa en el rango de auditorias ya sea una alarma o una auditoria
		if (myTransferOnlyCritical)
			module = [[CommercialStateMgr getInstance] getModuleByCode: ModuleCode_SEND_ALARMS];
		else
			module = [[CommercialStateMgr getInstance] getModuleByCode: ModuleCode_SEND_AUDITS];

		/* Recorre las auditorias */		
		while (![auditsRS eof]) {	

			//doLog(0,"auditid = %ld\n", [auditsRS getLongValue: "AUDIT_ID"]);
			//doLog(0,"EVENT_ID = %d\n", [auditsRS getShortValue: "EVENT_ID"]);

			// Verifica si ya me pase del numero de audit hasta (solo para filtro por id)
			if (myFilterType == ID_INFO_FILTER && [auditsRS getLongValue: "AUDIT_ID"] > myToId) {
				break; 
			}

  		myNextLastAlarmIdTransfered = [auditsRS getLongValue: "AUDIT_ID"];

      if ((myTransferOnlyCritical) && ([self isCriticalAudit: [auditsRS getShortValue: "EVENT_ID"]])) {
  			 formatRecord = TRUE;

       } else {

          if (!myTransferOnlyCritical) {

            if ((![self isCriticalAudit: [auditsRS getShortValue: "EVENT_ID"]]) && ([auditsRS getLongValue: "AUDIT_ID"] >= myLastAuditIdTransfered)) {

              formatRecord = TRUE;
              myNextLastAuditIdTransfered = [auditsRS getLongValue: "AUDIT_ID"];

            } else {

              if (([self isCriticalAudit: [auditsRS getShortValue: "EVENT_ID"]]) && ([auditsRS getLongValue: "AUDIT_ID"] >= myLastAlarmIdTransfered)) {

                formatRecord = TRUE;
//                myNextLastAlarmIdTransfered = [auditsRS getLongValue: "AUDIT_ID"];

              } 

            }              
          }       
       }

			// ontengo las fechas segun el modo de ejecucion
			if (myExecutionMode == PIMS_TSUP_ID) {
				date = [module getBaseDateTime];
				moduleBaseDateTime = [SystemTime convertToLocalTime: date];
	
				date = [module getExpireDateTime];
				moduleExpireDateTime = [SystemTime convertToLocalTime: date];

				hoursQty = [module getHoursQty];
			} else {
				// para el resto de los casos le pongo la misma fecha para que siempre pase el if
				moduleBaseDateTime = [auditsRS getDateTimeValue: "DATE"];
				moduleExpireDateTime = [auditsRS getDateTimeValue: "DATE"];
				hoursQty = 0;
			}
			
			// la fecha de la auditoria se debe encontrar entre la fecha base y la fecha de expiracion
			// este control solo se aplica si se supervisa a la PIMS

      if (formatRecord /*&& 
					( (([auditsRS getDateTimeValue: "DATE"] >= moduleBaseDateTime ) && 
					   ([auditsRS getDateTimeValue: "DATE"] <= moduleExpireDateTime)) ||
						(([auditsRS getDateTimeValue: "DATE"] >= moduleBaseDateTime ) && 
					   (hoursQty == 0)))*/) {

   			if ( ([auditsRS getCharValue: "HAS_CHANGE_LOG"]) && ([changeLogRS eof] || 
							[changeLogRS getLongValue: "AUDIT_ID"] != [auditsRS getLongValue: "AUDIT_ID"])) {

				  [changeLogRS findFirstById: "AUDIT_ID" value: [auditsRS getLongValue: "AUDIT_ID"]];

				}

			  n = [myInfoFormatter formatAudit: myBuffer audits: auditsRS  changeLog: changeLogRS];
			 
				assert(n > 0);
			
				if (n != 0)
					if ([self writeToRequestDataFile: myBuffer size: n] <= 0)
						THROW( TSUP_GENERAL_EX );
  					
  			formatRecord = FALSE;

				fileSize += n;			

				// si llego al maximo permitido corta
				if ([self reachMaxFileSize: fileSize maxFileSize: MAX_AUDITS_FILE_SIZE]) 
					break;
				
  		}

			if (![auditsRS moveNext]) break;

		}

	FINALLY

		[auditsRS close]; 
		[auditsRS free];	


	END_TRY;
}

/**/
- (void) endRequestDataFile
{
	/* Configura el valor de la auditoria transferida */
//	doLog(0,"myFilterType = %d\n", myFilterType);

	if (myFilterType == NOT_TRANSFER_INFO_FILTER) {

//	doLog(0,"guarda el ultimo id de auditoria enviada = %d\n", myNextLastAuditIdTransfered);		

		[[TelesupFacade getInstance] setTelesupParamAsLong: "LastTelesupAuditId" 
						value: myNextLastAuditIdTransfered telesupRol: myReqTelesupRol];
						
		[[TelesupFacade getInstance] setTelesupParamAsLong: "LastTelesupAlarmId" 
						value: myNextLastAlarmIdTransfered telesupRol: myReqTelesupRol];

		[[TelesupFacade getInstance] telesupApplyChanges: myReqTelesupRol];
						
	}
}

/**/
- (void) setTransferOnlyCritical: (BOOL) aValue
{
	myTransferOnlyCritical = aValue;
}

/**/
- (BOOL) isCriticalAudit: (unsigned long) anEventId
{
	id event;
	
	event = [[EventManager getInstance] getEvent: anEventId];  

	if (!event) return FALSE;

	if ([event isCritical]) return TRUE;

	return FALSE;
}

/**/
- (void) setExecutionMode: (int) aValue
{
	myExecutionMode = aValue;
}

@end


