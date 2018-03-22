/*
 * GV : 07-03-2005: Las invocaciones a los metodos
 * 				getCallTrafficRecordSet, getCallTrafficRecordSetById,
 *				getCallTrafficRecordSetByDate y getCallAmountsRecordSet se cambiaron
 *				por getCallsTrafficRecordSet, getCallsTrafficRecordSetById,
 *				getCallsTrafficRecordSetByDate y getCallsAmountsRecordSet respectivamente.
 */

#include "GetAppliedMessagesRequest.h"
#include "assert.h"
#include "system/util/all.h"

#include "TelesupFacade.h"
#include "TransferInfoFacade.h"

#include "RequestDAO.h"

			
/* macro para debugging */
//#define printd(args...) doLog(args)
#define printd(args...)



static GET_APPLIED_MESSAGES_REQUEST mySingleInstance = nil;
static GET_APPLIED_MESSAGES_REQUEST myRestoreSingleInstance = nil;

@implementation GetAppliedMessagesRequest

/**/
+ getSingleVarInstance
{
	 return mySingleInstance; 
};

+ (void) setSingleVarInstance: (id) aSingleVarInstance
{
	 mySingleInstance =  aSingleVarInstance;
};

/**/
+ getRestoreVarInstance 
{
	 return myRestoreSingleInstance; 
};

+ (void) setRestoreVarInstance: (id) aRestoreVarInstance
{
	 myRestoreSingleInstance = aRestoreVarInstance; 
};

/**/
- initialize
{
	[super initialize];
	[self setReqType: GET_APPLIED_MESSAGES_REQ];
	return self;
}

/**/

- (void) clearRequest
{
	myFilterType = NOT_TRANSFER_INFO_FILTER;
	myFromId = 0;
	myToId = 0;			
};

/**/
- (void) setFromId: (int) aFromId { myFromId = aFromId; };
/**/
- (void) setToId: (int) aToId { myToId = aToId; };

/**/
- (void) setFilterInfoType: (int) aFilterType { myFilterType = aFilterType; };

/**/
- (void) sendRequestData
{
	REQUEST request;
	ABSTRACT_RECORDSET rs = NULL;
	long lastMessageTransfered = 0;

	assert(myInfoFormatter);
	assert(myTelesupErrorMgr);
	
	/**/
	switch (myFilterType) {
		
		case NOT_TRANSFER_INFO_FILTER:								  
			lastMessageTransfered = [[TelesupFacade getInstance] getTelesupParamAsLong: "LastTelesupMessageId" 
																			telesupRol: myReqTelesupRol];
			myFromId = lastMessageTransfered + 1;
			
			/* obtener el recordser del RequestDAO filtrado */			
			rs = [[TransferInfoFacade getInstance] getAppliedRequestsRecordSetByRol: myReqTelesupRol
															fromMessageId: myFromId toMessageId: 0];
			
			break;

		case ID_INFO_FILTER:
			
			if (myFromId > myToId)
				THROW( TSUP_INVALID_FILTER_EX );
			
			/* obtener el recordser del RequestDAO filtrado */
			rs = [[TransferInfoFacade getInstance] getAppliedRequestsRecordSetByRol: myReqTelesupRol 
														fromMessageId: myFromId toMessageId: myToId];
			
			break;		

		default:
			THROW( TSUP_INVALID_FILTER_EX );
			break;
	}	

	assert(rs);
	[rs open];
	[rs moveBeforeFirst];

	TRY
	
		/* Recorre los requests */		
		while ([rs moveNext]) {	
	
			/**/
			request = [RequestDAO getRequestFromRecordSet: rs];
				
			/* Si el Reuqest esta sin ejecutar no se envia su estado */
			if ([request getReqTelesupRol] != myReqTelesupRol)
				continue;
			
			/* esto lo sacare cuando pueda obtener recordsets fltrados */	
			switch (myFilterType) {
			
				case NOT_TRANSFER_INFO_FILTER:								  
					
					if ([request getReqMessageId] < myFromId)
						continue;
						
					break;
	
				case ID_INFO_FILTER:
					
					if ([request getReqMessageId] < myFromId || [request getReqMessageId] > myToId)
						continue;
						
					break;
			}	
						
				
			/* por ahora queda asi, mas adelante modificare el proxy para que quede bien abstracto y
			no quede dependiente del ptsd */
			
			/* comienza el sub-mensaje */
			[myRemoteProxy addLine: "Response"];
			
			/* El contenido del sub-mensaje */
			[myRemoteProxy addParamAsInteger: "MessageId" value: [request getReqMessageId]];
			
			/* Si la ejecucion es exitosa ... */
			if (![request isReqFailed]) 
				[myRemoteProxy addParamAsString: "Status" value: "Ok"];
			else {
				[myRemoteProxy addParamAsString: "Status" value: "Error"];
				[myRemoteProxy addParamAsInteger: "Code" value: 
						[myTelesupErrorMgr getErrorCode: [request getReqMessageId]]];
			}
			
			/* finaliza el sub-mensaje */
			[myRemoteProxy addLine: "EndResponse"];
					
			/**/
			lastMessageTransfered = [request getReqMessageId];
		}

	FINALLY
		
			[rs close];
			[rs free];
			
	END_TRY;
	
	/* Configura el valor de la ultima llamada transferida */
	if (myFilterType == NOT_TRANSFER_INFO_FILTER) 
		[[TelesupFacade getInstance] setTelesupParamAsLong: "LastTelesupMessageId" 
							value: lastMessageTransfered telesupRol: myReqTelesupRol];
}

@end


