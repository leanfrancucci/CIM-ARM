#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <ctype.h>
#include "system/lang/all.h"
#include "system/util/all.h"
#include "ctapp.h"
#include "TITelesupParser.h"
#include "Request.h"
#include "GetFileRequest.h"
#include "GetAuditsRequest.h"
#include "Configuration.h"
#include "ctversion.h"
#include "GetDepositsRequest.h"
#include "GetZCloseRequest.h"

#define printd(args...)// doLog(0,args)
//#define printd(args...)

@implementation TITelesupParser


/**/
+ new
{
	return [[super new] initialize];
}


/**/
- initialize
{
	strcpy(systemId, "");
	return self;
}

/**/
- (void) setSystemId: (char *) aSystemId
{
	strcpy(systemId, aSystemId);
}

/**
 * Debe ser llamada cada vez que se crea un Request
 */
- (void) configureRequest: (REQUEST) aRequest type: (int) reqType operation: (ENTITY_REQUEST_OPS) aReqOp 
{ 
	[aRequest setReqOperation: aReqOp];
}

/**/
- (REQUEST) getNewSendAuditRequest:(int)filtered fromDate:(datetime_t)fDate toDate:(datetime_t)tDate
{
	char sourcePath[255];
	REQUEST request;	

	/* Crea el Request */
	request = [GetAuditsRequest new];

	/**/
	[self configureRequest: request type: GET_DATA_FILE_REQUEST_TYPE operation: NO_REQ_OP];	

	/* El nombre del archivo destino */
	sprintf(sourcePath, "%s/%s", [[Configuration getDefaultInstance] getParamAsString: "IMAS_FILES_TO_SEND_PATH"], "audits.auc" );
	printd("Filename mio %s\n",sourcePath);
	[request setSourceFileName: sourcePath];
	
	/*anulo el envio del archivo al finalizar la creacion*/	
	[request setSendFile: FALSE ];
		
	/* El filtro de tickets */	
	if (filtered){
		[request setFilterInfoType: DATE_INFO_FILTER];
		[request setFromDate: fDate];
		[request setToDate: tDate];
	}
	else
		[request setFilterInfoType: NOT_TRANSFER_INFO_FILTER];			
			
	return request;
}

/**/
- (REQUEST) getNewGetDepositsRequest:(int)filtered fromDate:(datetime_t)fDate toDate:(datetime_t)tDate
{
	char sourcePath[255];
	REQUEST request;	

	/* Crea el Request */
	request = [GetDepositsRequest new];

	/**/
	[self configureRequest: request type: GET_DEPOSITS_REQ operation: NO_REQ_OP];

	/* El nombre del archivo destino */
	sprintf(sourcePath, "%s/%s", [[Configuration getDefaultInstance] getParamAsString: "IMAS_FILES_TO_SEND_PATH"], "deposits.trc" );
	printd("Filename mio %s\n",sourcePath);
	[request setSourceFileName: sourcePath];
	
	/*anulo el envio del archivo al finalizar la creacion*/	
	[request setSendFile: FALSE ];
		
	/* El filtro de tickets */	
	if (filtered){
		[request setFilterInfoType: DATE_INFO_FILTER];
		[request setFromDate: fDate];
		[request setToDate: tDate];
	}
	else
		[request setFilterInfoType: NOT_TRANSFER_INFO_FILTER];			
			
	return request;
}

/**/
- (REQUEST) getNewSendTrafficRequest:(int)filtered fromDate:(datetime_t)fDate toDate:(datetime_t)tDate
{
	return NULL;
}

/**/
- (REQUEST) getRequest: (char *) aMessage activateFilter:(int)filtered fromDate:(datetime_t)fDate toDate:(datetime_t)tDate
{	
	REQUEST request = NULL;


	/* Generacion de auditorias*/
	if (strcmp(aMessage, "GET_AUDITS_IMAS") == 0) {
		printd("Get Audits\n");
		request = [self getNewSendAuditRequest: filtered fromDate:fDate toDate:tDate];
		printd("Get Audits OK\n");		
		return request;
	}

	/* Generacion de depositos */
	if (strcmp(aMessage, "GetDeposits") == 0) {
		printd("Get Deposits\n");
		request = [self getNewGetDepositsRequest: filtered fromDate:fDate toDate:tDate];
		printd("Get Deposits OK\n");
		return request;
	}

	return request;
}


@end

