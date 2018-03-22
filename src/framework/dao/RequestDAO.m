#include <string.h>
#include "util.h"
#include "RequestDAO.h"
#include "system/db/all.h"
#include "FilteredRecordSet.h"
#include "TelesupFactory.h"

#define printd(args...)		

#define REQUESTS_TABLE_NAME			"requests"

/**/
@implementation RequestDAO


#if 0

/**/
static ABSTRACT_RECORDSET myRequestRecordSet = NULL;

/**/
+ new
{
	/**/
	myRequestRecordSet = [[DBConnection getInstance] createRecordSet: REQUESTS_TABLE_NAME];	
	assert(myRequestRecordSet);
	
	return [[super new] initialize];
}

/**/
- initialize
{
	[super initialize];

	myRecordSet = [[DBConnection getInstance] createRecordSet: REQUESTS_TABLE_NAME];	
	[myRecordSet open];

	/* El recordset para las sub tablas */
	mySubRecordSet = [[DBConnection getInstance] createRecordSet: [self getSubTableName]];
	[mySubRecordSet open];
	
	return self;
}

/**/
- free
{
	[myRecordSet close];
	[myRecordSet free];

	[mySubRecordSet close];
	[mySubRecordSet free];

	return [super free];
}

/**/
- (char *) getSubTableName
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;	
}

/**/
- (REQUEST) getRequestInstance
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}
;

/**/
- (void) loadRequestToRecordSet: (REQUEST) aRequest recordSet: (ABSTRACT_RECORDSET) aRecordSet
{
	THROW( ABSTRACT_METHOD_EX );
}


/**/
- (void) loadRequestFromRecordSet: (REQUEST) aRequest recordSet: (ABSTRACT_RECORDSET) aRecordSet
{
	THROW( ABSTRACT_METHOD_EX );
}

/**/
- (void) store: (id) anObject
{
	unsigned long reqid;

	printd("RequestDAO.store([%ld])\n", [anObject getReqId]);

	/* Agrega el registro en la tabla principal */
	if ([anObject getReqId] > 0)
		[myRecordSet findById: "REQ_ID" value: [anObject getReqId]];
	else
		[myRecordSet add];
		
	/* Datos comunes a todos los Request */
	[myRecordSet setCharValue:	  	"TYPE" 			value: [anObject getReqType]];
	[myRecordSet setCharValue:  	"TELESUP_ID" 	value: [anObject getReqTelesupId]];
	[myRecordSet setCharValue: 		"ROL" 			value: [anObject getReqTelesupRol]];
	[myRecordSet setCharValue: 		"OPERATION" 	value: [anObject getReqOperation]];
	[myRecordSet setLongValue:  	"JOB_ID" 		value: [anObject getReqJobId]];
	[myRecordSet setLongValue:  	"MESSAGE_ID" 	value: [anObject getReqMessageId]];
	[myRecordSet setCharValue: 		"EXECUTED" 		value: [anObject isReqExecuted]];
	[myRecordSet setShortValue: 	"ERROR_CODE" 	value: [anObject getReqErrorCode]];

	/* Graba el registro */
	[myRecordSet save];
	reqid = [myRecordSet getLongValue:  "REQ_ID"];
	[anObject setReqId: reqid];

	/* Agrega un registro en la sub tabla */
	if (reqid > 0)
		[mySubRecordSet findById: "REQ_ID" value: reqid];
	else
		[mySubRecordSet add];
		
	assert([anObject getReqId] > 0);
	
	[mySubRecordSet setLongValue: "REQ_ID" value: reqid];
	/* Llama al metodo hook esta definido en la subclase especifica del request */
	[self loadRequestToRecordSet: anObject recordSet: mySubRecordSet];
	
	/* Graba el registro */
	[mySubRecordSet save];	
}


/**/
- (id) loadById: (unsigned long) anObjectId
{
	REQUEST request;

	printd("RequestDAO.loadById()\n");

	/* Busca el registro correspondiente en la tabla de requests */
	if ( ![myRecordSet findById: "REQ_ID" value: anObjectId] )
		THROW( NO_CURRENT_RECORD_EX );

	/* busca el registro correspondiente en la subtabla de request */
	if (![mySubRecordSet findById: "REQ_ID" value: anObjectId])
		THROW( NO_CURRENT_RECORD_EX );

	/* Obtiene el request adecuado en base al subtipo correspondiente */
	request = [self getRequestInstance];

	/* Datos comunes a todos los Request */
	[request setReqId: 			anObjectId];
	[request setReqType: 		[myRecordSet getCharValue: "TYPE"]];	
	[request setReqTelesupId: 	[myRecordSet getCharValue: "TELESUP_ID"]];		
	[request setReqTelesupRol: 	[myRecordSet getCharValue: "ROL"]];
	[request setReqOperation: 	[myRecordSet getCharValue: "OPERATION"]];
	[request setReqJobId: 		[myRecordSet getLongValue: "JOB_ID"]];
	[request setReqMessageId: 	[myRecordSet getLongValue: "MESSAGE_ID"]];
	[request setReqExecuted: 	[myRecordSet getCharValue: "EXECUTED"]];
	[request setReqErrorCode: 	[myRecordSet getCharValue: "ERROR_CODE"]];
	
	if ([request getReqErrorCode] > 0)
		[request setReqFailed: TRUE];
	else
		[request setReqFailed: FALSE];	
		
	/* Configura el error manager */
	//[request setTelesupErrorManager: [[TelesupFactory getInstance] getTelesupErrorManager: [request getReqTelesupId]]];

	/* Carga los datos del recordset en el Request con el metodo hook */
	[self loadRequestFromRecordSet: request recordSet: mySubRecordSet];

	return request;
};

/**/
+ (ABSTRACT_RECORDSET) createRequestRecordSet
{
	return [[DBConnection getInstance] createRecordSet: REQUESTS_TABLE_NAME];	
}


/**/
+ (ABSTRACT_RECORDSET) getNotAppliedRequestsRecordSetByRol: (int) aTelesupRol
									fromMessageId: (unsigned long) aFromId toMessageId: (unsigned long) aToId
{
	FILTERED_RECORDSET recordSet;
	
	recordSet = [[FilteredRecordSet new] 
							initWithRecordset: [[DBConnection getInstance] createRecordSet: REQUESTS_TABLE_NAME]];
	
	[recordSet addCharFilter: "ROL" operator: "=" value: aTelesupRol];
	[recordSet addCharFilter: "EXECUTED" operator: "=" value: FALSE];
	
	if (aFromId > 0)
		[recordSet addLongFilter: "MESSAGE_ID" operator: ">=" value: aFromId];

	if (aToId > 0)
		[recordSet addLongFilter: "MESSAGE_ID" operator: "<=" value: aToId];
		
	return recordSet;
}

/**/
+ (ABSTRACT_RECORDSET) getAppliedRequestsRecordSetByRol: (int) aTelesupRol
									fromMessageId: (unsigned long) aFromId toMessageId: (unsigned long) aToId
{
	FILTERED_RECORDSET recordSet;
	
	recordSet = [[FilteredRecordSet new] 
							initWithRecordset: [[DBConnection getInstance] createRecordSet: REQUESTS_TABLE_NAME]];
	
	[recordSet addCharFilter: "ROL" operator: "=" value: aTelesupRol];
	[recordSet addCharFilter: "EXECUTED" operator: "=" value: TRUE];
	
	if (aFromId > 0)
		[recordSet addLongFilter: "MESSAGE_ID" operator: ">=" value: aFromId];

	if (aToId > 0)
		[recordSet addLongFilter: "MESSAGE_ID" operator: "<=" value: aToId];
	
	return recordSet;
/*
	ABSTRACT_RECORDSET recordSet;
	recordSet = [[DBConnection getInstance] createRecordSet: REQUESTS_TABLE_NAME];
	return recordSet;
*/	
}

/**/
+ (REQUEST) getRequestFromRecordSet: (ABSTRACT_RECORDSET) aRecordSet
{
	return [self getRequestById: [aRecordSet getLongValue: "REQ_ID"]
									requestType: [aRecordSet getCharValue: "TYPE"]];
}

/**/
+ (REQUEST) getRequestById: (unsigned long) anId
{
	int type;
	
	assert(myRequestRecordSet);
	
	[myRequestRecordSet open];	
	
	/* Busca el registro correspondiente en la tabla de requests */
	if ( ![myRequestRecordSet findById: "REQ_ID" value: anId] ) 
		THROW( NO_CURRENT_RECORD_EX );
	
	type = [myRequestRecordSet getCharValue: "TYPE"];	
	
	[myRequestRecordSet close];
	
	return [self getRequestById: anId requestType: type];	
}

/**/
+ (REQUEST) getRequestById: (unsigned long) anId requestType: (int) aRequestType
{
	id requestDAO;

	if (anId == 0)
		THROW( INDEX_OUT_OF_BOUNDS_EX );
		
	if (aRequestType == 0)
		THROW( INDEX_OUT_OF_BOUNDS_EX );
		
	switch ( aRequestType ) {

		/**/
		case SET_AMOUNT_MONEY_REQ:			
			requestDAO = [SetAmountMoneyRequestDAO getInstance];
			break;
			
		/**/
		case SET_COMMERCIAL_STATE_REQ:
			requestDAO = [SetCommercialStateRequestDAO getInstance];
			break;
			
		/**/
		case SET_EVENTS_SETTINGS_REQ:
			requestDAO = [SetEventsSettingsRequestDAO getInstance];
			break;
			
		/**/
		case SET_GENERAL_BILL_REQ:
			requestDAO = [SetGeneralBillRequestDAO getInstance];
			break;
			
		/**/
		case SET_OPERATION_BY_USER_PROFILE_REQ:
			requestDAO = [SetOperationByUserProfileRequestDAO getInstance];
			break;
			
		/**/
		case SET_REGIONAL_SETTINGS_REQ:
			requestDAO = [SetRegionalSettingsRequestDAO getInstance];
			break;
			
		/**/
		case SET_USER_PROFILE_REQ:
			requestDAO = [SetUserProfileRequestDAO getInstance];
			break;
			
		/**/
		case SET_USER_REQ:
			requestDAO = [SetUserRequestDAO getInstance];
			break;

#if 0
		/**/
		case XXXXXXXXXX_REQ:
			requestDAO = [XXXXXXXXXXRequestDAO getInstance];
			break;
#endif

		default:
			THROW( TSUP_INVALID_REQUEST_EX );
	}

	return [requestDAO loadById: anId];
}
#endif
									
@end
