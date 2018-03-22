#include "ExtractionDAO.h"
#include "Extraction.h"
#include "ExtractionDetail.h"
#include "CurrencyManager.h"
#include "system/db/all.h"
#include "UserManager.h"
#include "CimManager.h"
#include "CimBackup.h"
#include "FilteredRecordSet.h"
#include "Persistence.h"
#include "BagTrack.h"
#include "CimGeneralSettings.h"

//#define LOG(args...) doLog(0,args)
//#define printd(args...)

@implementation ExtractionDAO

static EXTRACTION_DAO singleInstance = NULL;

/**/
- (ABSTRACT_RECORDSET) getNewExtractionRecordSet
{
	ABSTRACT_RECORDSET recordSet;

	recordSet = [[DBConnection getInstance] createRecordSet: "extractions"];
	[recordSet setDateField: "DATE_TIME"];
	[recordSet setIdField: "NUMBER"];

	return recordSet;
}

/**/
- (ABSTRACT_RECORDSET) getNewExtractionDetailRecordSet
{
	ABSTRACT_RECORDSET recordSet;

	recordSet = [[DBConnection getInstance] createRecordSet: "extraction_details"];
	[recordSet setDateField: ""];
	[recordSet setMaxRecordCount: INFINITE_MAX_RECORD_COUNT];
	[recordSet setIdField: "NUMBER"];

	return recordSet;
}

/**/
- (ABSTRACT_RECORDSET) getNewBagTrackingRecordSet
{
	ABSTRACT_RECORDSET recordSet;

	//recordSet = [[DBConnection getInstance] createRecordSet: "bag_tracking"];
	recordSet = [[MultiPartRecordSet new] initWithTableName: "bag_tracking"];
	[recordSet setIdField: "BAG_TRACKING_ID"];
	[recordSet setDateField: ""];
	[recordSet setAutoFlush: TRUE];

	return recordSet;
}

/**/
- initialize
{
	[super initialize];

/** @todo: ver cuestiones de flush y cuando se corta un registro de detalle */

	myExtractionRS = [self getNewExtractionRecordSet];
	[myExtractionRS open];

  myExtractionDetailRS = [self getNewExtractionDetailRecordSet];
	[myExtractionDetailRS open];

	myBagTrackingRS = [self getNewBagTrackingRecordSet];
	[myBagTrackingRS open];

	return self;
}

/**/
+ new
{
	if (!singleInstance) singleInstance = [super new];
	return singleInstance;
}

/**/
+ getInstance
{
	return [self new];
}

/**/
- free
{
	[myExtractionRS free];
	[myExtractionDetailRS free];
	[myBagTrackingRS free];
	return [super free];
}

/**/
- (void) deleteAll
{
	[myExtractionRS deleteAll];
	[myExtractionDetailRS deleteAll];
	[myBagTrackingRS deleteAll];
}

/**/
- (void) storeDetails: (id) anObject
{
	int i;
	COLLECTION details;
	EXTRACTION_DETAIL detail;

	details = [anObject getExtractionDetails];

	for (i = 0; i < [details size]; ++i) {

		detail = [details at: i];

		[myExtractionDetailRS add];

		[myExtractionDetailRS setLongValue: "NUMBER" value: [anObject getNumber]];
		[myExtractionDetailRS setShortValue: "CIM_CASH_ID" value: [[detail getCimCash] getCimCashId]];
		[myExtractionDetailRS setShortValue: "ACCEPTOR_ID" value: [[detail getAcceptorSettings] getAcceptorId]];
		[myExtractionDetailRS setCharValue: "DEPOSIT_VALUE_TYPE" value: [detail getDepositValueType]];
		[myExtractionDetailRS setShortValue: "QTY" value: [detail getQty]];
		[myExtractionDetailRS setMoneyValue: "AMOUNT" value: [detail getAmount]];
		[myExtractionDetailRS setShortValue: "CURRENCY_ID" value: [[detail getCurrency] getCurrencyId]];

		[myExtractionDetailRS save];

		[[CimBackup getInstance] syncRecord: "extraction_details" buffer: [myExtractionDetailRS getRecordBuffer]];

	}

}

/**/
- (void) store: (id) anObject
{
	unsigned long indexCount;

	//doLog(0,"ExtractionDAO -> Grabando extraction...\n");

	[myExtractionRS add];

	[myExtractionRS setShortValue: "DOOR_ID" value: [[anObject getDoor] getDoorId]];
	[myExtractionRS setDateTimeValue: "DATE_TIME" value: [anObject getDateTime]];
	[myExtractionRS setLongValue: "FROM_DEPOSIT_NUMBER" value: [anObject getFromDepositNumber]];
	[myExtractionRS setLongValue: "TO_DEPOSIT_NUMBER" value: [anObject getToDepositNumber]];
	[myExtractionRS setStringValue: "BANK_INFO" value: [anObject getBankAccountInfo]];

	if ([anObject getOperator])
		[myExtractionRS setLongValue: "OPERATOR_ID" value: [[anObject getOperator] getUserId]];

	if ([anObject getCollector])
		[myExtractionRS setLongValue: "COLLECTOR_ID" value: [[anObject getCollector] getUserId]];

	[myExtractionRS setLongValue: "NUMBER" value: [anObject getNumber]];
	[myExtractionRS setShortValue: "REJECTED_QTY" value: [anObject getRejectedQty]];

	[myExtractionRS setLongValue: "FROM_CLOSE_NUMBER" value: [anObject getFromCloseNumber]];
	[myExtractionRS setLongValue: "TO_CLOSE_NUMBER" value: [anObject getToCloseNumber]];

	indexCount = [myExtractionRS getIndexCount];

	[myExtractionRS save];

	[[CimBackup getInstance] syncRecord: "extractions" buffer: [myExtractionRS getRecordBuffer]];

	//doLog(0,"ExtractionDAO -> termino de grabar extraction...\n");
    //doLog(0,"ExtractionDAO -> Guardando detalle ...\n");

	// Verifica si se agrego un archivo mas a la lista de indices, con lo cual
	// debo generar los archivos correspondientes para la tabla de detalle de deposito.
	// En caso de que se este en la cantidad maxima de archivos de depositos verifico
	// por el metodo shouldCutFile pues si no [myDepositRS getIndexCount] siempre 
	// va a ser = a indexCount y nunca mas se crearia un nuevo archivo de detalle haciendo 
	// que este cree registros indefinidamente.
	if ( ([myExtractionRS getIndexCount] != indexCount) ||
			 ([myExtractionRS shouldCutFile]) ) {
		//doLog(0,"ExtractionDAO -> creo un nuevo archivo de detalle\n");
		[myExtractionDetailRS cutFile];
	}
	[myExtractionRS setShouldCutFile: FALSE];

	[self storeDetails: anObject];

	//doLog(0,"ExtractionDAO -> termino de grabar detalle...\n");

}

/**/
- (id) getExtractionHeaderFromRecordSet: (ABSTRACT_RECORDSET) aExtractionRS
{
	EXTRACTION extraction;
	char buf[51];

	// Creo el extractiono con los datos
	extraction = [Extraction new];
	[extraction setDoor: [[CimManager getInstance] getDoorById: [aExtractionRS getShortValue: "DOOR_ID"]]];
	[extraction setDateTime: [aExtractionRS getDateTimeValue: "DATE_TIME"]];
	[extraction setFromDepositNumber: [aExtractionRS getLongValue: "FROM_DEPOSIT_NUMBER"]];
	[extraction setToDepositNumber: [aExtractionRS getLongValue: "TO_DEPOSIT_NUMBER"]];
	[extraction setBankAccountInfo: [aExtractionRS getStringValue: "BANK_INFO" buffer: buf]];

	if ([aExtractionRS getLongValue: "OPERATOR_ID"] != 0)
		[extraction setOperator: [[UserManager getInstance] getUserFromCompleteList: [aExtractionRS getLongValue: "OPERATOR_ID"]]];

	if ([aExtractionRS getLongValue: "COLLECTOR_ID"] != 0)
		[extraction setCollector: [[UserManager getInstance] getUserFromCompleteList: [aExtractionRS getLongValue: "COLLECTOR_ID"]]];

	[extraction setNumber: [aExtractionRS getLongValue: "NUMBER"]];
	[extraction setRejectedQty: [aExtractionRS getShortValue: "REJECTED_QTY"]];

	[extraction setFromCloseNumber: [aExtractionRS getLongValue: "FROM_CLOSE_NUMBER"]];
	[extraction setToCloseNumber: [aExtractionRS getLongValue: "TO_CLOSE_NUMBER"]];

	return extraction;
}

/**/
- (id) getExtractionFromRecordSet: (ABSTRACT_RECORDSET) aExtractionRS extractionDetailRS: (ABSTRACT_RECORDSET) aExtractionDetailRS
{
	EXTRACTION extraction;
	COLLECTION extractionDetails;
	EXTRACTION_DETAIL extractionDetail;
	char buf[51];
	unsigned long i;
	id deposit;
	COLLECTION depositDetails = NULL;
	int x;
	money_t amount;

	// Creo el extractiono con los datos
	extraction = [Extraction new];
	[extraction setDoor: [[CimManager getInstance] getDoorById: [aExtractionRS getShortValue: "DOOR_ID"]]];
	[extraction setDateTime: [aExtractionRS getDateTimeValue: "DATE_TIME"]];
	[extraction setFromDepositNumber: [aExtractionRS getLongValue: "FROM_DEPOSIT_NUMBER"]];
	[extraction setToDepositNumber: [aExtractionRS getLongValue: "TO_DEPOSIT_NUMBER"]];
	[extraction setBankAccountInfo: [aExtractionRS getStringValue: "BANK_INFO" buffer: buf]];

	if ([aExtractionRS getLongValue: "OPERATOR_ID"] != 0)
		[extraction setOperator: [[UserManager getInstance] getUserFromCompleteList: [aExtractionRS getLongValue: "OPERATOR_ID"]]];

	if ([aExtractionRS getLongValue: "COLLECTOR_ID"] != 0)
		[extraction setCollector: [[UserManager getInstance] getUserFromCompleteList: [aExtractionRS getLongValue: "COLLECTOR_ID"]]];

	[extraction setNumber: [aExtractionRS getLongValue: "NUMBER"]];
	[extraction setRejectedQty: [aExtractionRS getShortValue: "REJECTED_QTY"]];

	[extraction setFromCloseNumber: [aExtractionRS getLongValue: "FROM_CLOSE_NUMBER"]];
	[extraction setToCloseNumber: [aExtractionRS getLongValue: "TO_CLOSE_NUMBER"]];

	if (![aExtractionDetailRS findFirstById: "NUMBER" value: [extraction getNumber]]) return extraction;

	extractionDetails = [extraction getExtractionDetails];

	// Creo cada uno de los detalles de extraction
	while (![aExtractionDetailRS eof] && [aExtractionDetailRS getLongValue: "NUMBER"] == [extraction getNumber]) {

		extractionDetail = [ExtractionDetail new];

		[extractionDetail setCimCash: [[CimManager getInstance] getCimCashById: [aExtractionDetailRS getShortValue: "CIM_CASH_ID"]]];
		[extractionDetail setDepositValueType: [aExtractionDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"]];
		[extractionDetail setAmount: [aExtractionDetailRS getMoneyValue: "AMOUNT"]];
		[extractionDetail setQty: [aExtractionDetailRS getShortValue: "QTY"]];
		[extractionDetail setCurrency: [[CurrencyManager getInstance] getCurrencyById: [aExtractionDetailRS getShortValue: "CURRENCY_ID"]]];
		[extractionDetail setAcceptorSettings: [[CimManager getInstance] getAcceptorSettingsById: [aExtractionDetailRS getShortValue: "ACCEPTOR_ID"]]];

		[extractionDetails add: extractionDetail];

		[aExtractionDetailRS moveNext];

	}

	// recorro los depositos incluidos en la extraccion para calcular las referencias
	i = [extraction getFromDepositNumber];
	while (i <= [extraction getToDepositNumber]) {
		deposit = [[[Persistence getInstance] getDepositDAO] loadById: i];

		if (deposit) {
			if ( ([deposit getCashReference] != NULL) && ([deposit getDoor] == [extraction getDoor]) ) {
				depositDetails = [deposit getDepositDetails];
				for (x=0; x<[depositDetails size]; x++) {
	
					if ([[depositDetails at: x] getDepositValueType] != DepositValueType_VALIDATED_CASH) 
						amount = [[depositDetails at: x] getAmount];
					else amount = [[depositDetails at: x] getAmount] * [[depositDetails at: x] getQty];
	
					[extraction addCashReferenceSummary: [deposit getCashReference] 
								currency: [[depositDetails at: x] getCurrency]
								amount: amount
								depositValueType: [[depositDetails at: x] getDepositValueType]
								depositType: [deposit getDepositType]];
				}
			}
			[deposit free];
		}
		i++;
	}

	return extraction;
}

/**/
- (void) loadBagTrackingByExtraction: (id) anExtraction
{
	COLLECTION bagTrackingList = NULL;
	COLLECTION envelopeTrackingList = NULL;
	id bagTrack;
	char buf[51];

	bagTrackingList = [Collection new];
	envelopeTrackingList = [Collection new];

	// levanto los bag traking ***********
	if ([myBagTrackingRS moveLast]) {

		// busca hasta que encuentra el numero de extraccion
		while (![myBagTrackingRS bof] && [myBagTrackingRS getLongValue: "EXTRACTION_NUMBER"] != [anExtraction getNumber]) [myBagTrackingRS movePrev];

		if ([myBagTrackingRS bof]) return;		

		// va hasta el primer registro
		while (![myBagTrackingRS bof] && [myBagTrackingRS getLongValue: "EXTRACTION_NUMBER"] == [anExtraction getNumber]) [myBagTrackingRS movePrev];

		// avanza uno para pararse en el primero
		[myBagTrackingRS moveNext];

		while (![myBagTrackingRS eof] && [myBagTrackingRS getLongValue: "EXTRACTION_NUMBER"] == [anExtraction getNumber]) {

			if ([myBagTrackingRS getLongValue: "PARENT_ID"] == 0) {
				[anExtraction setBagNumber: [myBagTrackingRS getStringValue: "NUMBER" buffer: buf]];
				[anExtraction setHasBagTracking: TRUE];
				[myBagTrackingRS moveNext];
			} else {
				bagTrack = [BagTrack new];
				[bagTrack setExtractionNumber: [myBagTrackingRS getLongValue: "EXTRACTION_NUMBER"]];
				[bagTrack setBNumber: [myBagTrackingRS getStringValue: "NUMBER" buffer: buf]];
				[bagTrack setBParentId: [myBagTrackingRS getLongValue: "PARENT_ID"]];
				[bagTrack setBType: [myBagTrackingRS getCharValue: "TYPE"]];

				if ([bagTrack getBType] == BagTrackingMode_MANUAL) [envelopeTrackingList add: bagTrack];
				if ([bagTrack getBType] == BagTrackingMode_AUTO) [bagTrackingList add: bagTrack];
		
				[myBagTrackingRS moveNext];
			}

			[anExtraction setBagTrackingCollection: bagTrackingList];
			[anExtraction setEnvelopeTrackingCollection: envelopeTrackingList];

		}
	}
}

/**/
- (id) loadById: (unsigned long) anId
{
	/** @todo: VER SI UTILIZO OTRO RECORDSET O ES SIEMPRE EL MISMO */
	if (![myExtractionRS findById: "NUMBER" value: anId]) return NULL;

	return [self getExtractionFromRecordSet: myExtractionRS extractionDetailRS: myExtractionDetailRS];
}

/**/
- (id) loadLast
{
	/** @todo: VER SI UTILIZO OTRO RECORDSET O ES SIEMPRE EL MISMO */
	if (![myExtractionRS moveLast]) return NULL;

	return [self getExtractionFromRecordSet: myExtractionRS extractionDetailRS: myExtractionDetailRS];
}

/**/
- (id) loadLastFromDoor: (int) aDoorId
{
	/** @todo: VER SI UTILIZO OTRO RECORDSET O ES SIEMPRE EL MISMO */
	if (![myExtractionRS moveLast]) return NULL;

	// Busco de atras para adelante la ultima extraccion para
	// esa puerta pero que haya tenido depositos asociados

	while (![myExtractionRS bof]) {

		if ([myExtractionRS getShortValue: "DOOR_ID"] == aDoorId &&
				[myExtractionRS getLongValue: "FROM_DEPOSIT_NUMBER"] > 0 &&
				[myExtractionRS getLongValue: "TO_DEPOSIT_NUMBER"] > 0) {
			return [self getExtractionFromRecordSet: myExtractionRS extractionDetailRS: myExtractionDetailRS];
		}

		[myExtractionRS movePrev];

	}

	return NULL;
}

/**/
- (unsigned long) getLastExtractionNumber
{
	if (![myExtractionRS moveLast]) 
		return [[CimBackup getInstance] getLastRowValue: "extractions" field: "NUMBER"];

	return [myExtractionRS getLongValue: "NUMBER"];
}

/**/
- (ABSTRACT_RECORDSET) getExtractionRecordSetByDate: (datetime_t) aFromDate to: (datetime_t) aToDate
{
	FILTERED_RECORDSET recordSet; 
	
	recordSet = [[FilteredRecordSet new] initWithRecordset: [self getNewExtractionRecordSet]];
	
	if (aFromDate > 0)
		[recordSet addLongFilter: "DATE_TIME" operator: ">=" value: aFromDate];
		
	if (aToDate > 0)
		[recordSet addLongFilter: "DATE_TIME" operator: "<=" value: aToDate];
								
	return recordSet;		

}

/**/
- (unsigned long) storeBagTracking: (id) anObject
{
	unsigned long bagTrackingId;

	//[anObject debugBagTrack];

	// agrega el nuevo track
	[myBagTrackingRS add];

	[myBagTrackingRS setLongValue: "EXTRACTION_NUMBER" value: [anObject getExtractionNumber]];
	[myBagTrackingRS setStringValue: "NUMBER" value: [anObject getBNumber]];
	[myBagTrackingRS setLongValue: "PARENT_ID" value: [anObject getBParentId]];
	[myBagTrackingRS setCharValue: "TYPE" value: [anObject getBType]];

	bagTrackingId = [myBagTrackingRS save];
	//doLog(0, "------------------- save bagTrack id = %ld  ----------------\n", bagTrackingId);

	return bagTrackingId;
}

/**/
- (id) loadExtractionHeaderByNumber: (unsigned long) aNumber
{
	/** @todo: VER SI UTILIZO OTRO RECORDSET O ES SIEMPRE EL MISMO */
	if (![myExtractionRS moveLast]) return NULL;

	while (![myExtractionRS bof] && [myExtractionRS getLongValue: "NUMBER"] != aNumber)
		[myExtractionRS movePrev];

	if ([myExtractionRS bof]) return NULL;

	if ([myExtractionRS getLongValue: "NUMBER"] == aNumber) 
		return [self getExtractionHeaderFromRecordSet: myExtractionRS];

	return NULL;
	
}

/**/
- (unsigned long) loadBagTrackParentIdByExtraction: (unsigned long) aNumber type: (int) aType
{
	if (![myBagTrackingRS moveLast]) return 0;

	while (![myBagTrackingRS bof] && [myBagTrackingRS getLongValue: "EXTRACTION_NUMBER"] != aNumber) 
		[myBagTrackingRS movePrev];
	
	if ([myBagTrackingRS bof]) return 0;
	
	// va hasta el primer registro
	while (![myBagTrackingRS bof] && [myBagTrackingRS getLongValue: "EXTRACTION_NUMBER"] == aNumber) {

		if ([myBagTrackingRS getLongValue: "PARENT_ID"] == 0 && [myBagTrackingRS getCharValue: "TYPE"] == aType) return [myBagTrackingRS getLongValue: "BAG_TRACKING_ID"];

		[myBagTrackingRS movePrev];
	}

	return 0;
	
}

/**/
- (COLLECTION) storeAutoBagTrack: (id) anObject
{
	unsigned long bagTrackingId = 0;
	COLLECTION bagTrackingCollection = [Collection new];
	id bagTrack;
	char buf[51];
	ABSTRACT_RECORDSET rs = [self getNewBagTrackingRecordSet];

	[rs open];
	[rs moveLast];

	//[anObject debugBagTrack];
	
	// si no encuentra un registro con extractionNumber = 0 y parentid = 0
	// quiere decir que es el primero y debe guardar 

	while (![rs bof] && ([rs getLongValue: "EXTRACTION_NUMBER"] != 0 || [rs getLongValue: "PARENT_ID"] != 0)) 
		[rs movePrev];

	// si no lo encontro lo agrega
	if ([rs bof]) {

		[rs add];
		[rs setLongValue: "EXTRACTION_NUMBER" value: [anObject getExtractionNumber]];
		[rs setStringValue: "NUMBER" value: [anObject getBNumber]];
		[rs setLongValue: "PARENT_ID" value: [anObject getBParentId]];
		[rs setCharValue: "TYPE" value: [anObject getBType]];
	
		[rs save];
		[rs flush];

	}

	// si lo encuentra lo modifica y modifica sus hijos y los devuelve en una collection
	if ( ([rs getLongValue: "EXTRACTION_NUMBER"] == 0) && ([rs getLongValue: "PARENT_ID"] == 0) ) {
		[rs setLongValue: "EXTRACTION_NUMBER" value: [anObject getExtractionNumber]];
		[rs setStringValue: "NUMBER" value: [anObject getBNumber]];
		[rs setLongValue: "PARENT_ID" value: [anObject getBParentId]];
		[rs setCharValue: "TYPE" value: [anObject getBType]];

		[rs save];
		[rs flush];

		bagTrackingId = [rs getLongValue: "BAG_TRACKING_ID"];
		//doLog(0, "------------------- save bagTrack id = %ld  ----------------\n", bagTrackingId);
		// avanza en uno, porque asumo que los hijos estan despues SIEMPRE
		[rs moveNext];

		while (![rs eof] && [rs getLongValue: "PARENT_ID"] == bagTrackingId) {

			[rs setLongValue: "EXTRACTION_NUMBER" value: [anObject getExtractionNumber]];
	
			[rs save];
			[rs flush];

			bagTrack = [BagTrack new];
			[bagTrack setExtractionNumber: [rs getLongValue: "EXTRACTION_NUMBER"]];
			[bagTrack setBNumber: [rs getStringValue: "NUMBER" buffer: buf]];
			[bagTrack setBParentId: [rs getLongValue: "PARENT_ID"]];
			[bagTrack setBType: [rs getCharValue: "TYPE"]];

			//[bagTrack debugBagTrack];

			[bagTrackingCollection add: bagTrack];
			
			[rs moveNext];
		}

	}

	[rs close];
	[rs free];
	return bagTrackingCollection;


}

@end
