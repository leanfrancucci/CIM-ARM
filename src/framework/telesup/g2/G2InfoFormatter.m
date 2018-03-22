#include <math.h>
#include "system/util/all.h"

#include "TelesupDefs.h"
#include "G2InfoFormatter.h"
#include "Persistence.h"
#include "UserManager.h"
#include "CimDefs.h"
#include "ZCloseManager.h"
#include "CimManager.h"
#include "Event.h"
#include "DepositDetailReport.h"
#include "CimGeneralSettings.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

/**/
decimal_t moneyToDecimal2(money_t value)
{
	decimal_t d;
	int tocut;

	tocut = digits_to_cut(value);
	d.mantise = cut_digits(value, tocut);
	d.exp     = tocut - MONEY_DECIMAL_DIGITS;
	
	return d;
}


@implementation G2InfoFormatter


- (int) getBagTrackingMode: (id) aDoor;

/**/
- initialize
{
	[super initialize];
	
	return self;
}


/**/
- (int) writeDateTime: (datetime_t) aValue
{
	return [self writeLong: aValue];
}

/**/
- (datetime_t) readDateTime
{
	return [self readLong];
}

 
/**/
- (int) writeDouble: (double) aValue
{
	int i;
	decimal_fp fp;

	/* devuelve el numero en punto flotante decimal */
	doubleToDecimalFloatPoint(aValue, &fp);

	i = [self writeByte: fp.exp];	
	i += [self writeLong: fp.mantise];
	return i;
}

/**/
- (double) readDouble
{
	decimal_fp fp;

	fp.exp = [self readChar];
	fp.mantise = [self readLong];
	return decimalFloatPointToDouble(&fp);
}

/**/
- (int) writeMoney: (money_t) aValue
{
	int n;
	decimal_t dec = moneyToDecimal2(aValue);
	n  = [self writeByte: dec.exp];
	n += [self writeLong: dec.mantise];
	return n;
}

/**/
- (money_t) readMoney
{
	return [self readDouble];
}

/**/ 
- (int) getAuditSize
{
	return 24;
}

/**/
- (int) formatAudit: (char *) aBuffer audits: (ABSTRACT_RECORDSET) auditsRS changeLog: (ABSTRACT_RECORDSET) changeLogRS
{
	char *detailQtyPtr;
	int count = 0;
	char *tmp;
	unsigned long auditId;
	unsigned short eventId, userId;
	
	assert(auditsRS);
	assert(changeLogRS);
	assert(aBuffer);
	
	/* REGISTRO DE AUDITORIA = 24  bytes */
	[self setBuffer: aBuffer];
	
	auditId = [auditsRS getLongValue: "AUDIT_ID"];
	
	/* Escribe la auditoria en el buffer */
	[self writeLong: auditId];
	eventId = [auditsRS getShortValue: "EVENT_ID"];
	[self writeShort: eventId];
	userId = [auditsRS getShortValue: "USER_ID"];
	[self writeShort: userId];
	[self writeChar: [auditsRS getCharValue: "SYSTEM_TYPE"]];
	[self writeDateTime: [auditsRS getDateTimeValue: "DATE"]];
	[self writeShort: [auditsRS getShortValue: "STATION"]];
	if ( eventId ==  Event_NEW_CODE_SEAL ){	
		/* Se supone que si se genero un nuevo codigo de cierre es porque el usuario tiene configurado
		   PIN dinamico */
	//	doLog(0,"Envio a la PIMS el evento de nuevo codigo cierre USUARIO %d CODIGO CIERRE %s\n", userId, [[[UserManager getInstance] getUser: userId] getClosingCode] );
		[self writeString: [[[UserManager getInstance] getUser: userId] getClosingCode] qty: 20];
	} else 
		[self writeString: [auditsRS getStringValue: "ADDITIONAL" buffer: myTempBuffer]  qty: 20];
	
		// El detalle lo relleno despues
	detailQtyPtr = myBuffer;
	[self writeChar: 0];	

	//doLog(0,"verifica el changeLog auditId = %ld changeLogRS auditid = %ld\n", auditId, [changeLogRS getLongValue: "AUDIT_ID"]);
	

	while (![changeLogRS eof] && [changeLogRS getLongValue: "AUDIT_ID"] == auditId) {

			//doLog(0,"agrega el detalle audit id = %d\n", [changeLogRS getLongValue: "AUDIT_ID"]);
		/*
			Field long Referencia del campo
			OldValue char 40
			NewValue char 40
			Old reference long
			New reference long
		*/

	    [self writeLong: [changeLogRS getLongValue: "FIELD"]];
	    [self writeString: [changeLogRS getStringValue: "OLD_VALUE" buffer: myTempBuffer]  qty: 40];
	    [self writeString: [changeLogRS getStringValue: "NEW_VALUE" buffer: myTempBuffer]  qty: 40];
			[self writeLong: [changeLogRS getLongValue: "OLD_REFERENCE"]];
			[self writeLong: [changeLogRS getLongValue: "NEW_REFERENCE"]];

		count++;

		[changeLogRS moveNext];

	}

	// Aca escribo la cantidad de items, ya que no la calculo al inicio
	tmp = myBuffer;
	myBuffer = detailQtyPtr;
	[self writeChar: count];
	myBuffer = tmp;

//	doLog(0,"cantidad detalle = %d\n", count);

	return [self getLenInfo];	
}


/**/
- (int) formatDeposit: (char *) aBuffer
		includeDepositDetails: (BOOL) aIncludeDepositDetails
		deposits: (ABSTRACT_RECORDSET) aDepositRS
		depositDetails: (ABSTRACT_RECORDSET) aDepositDetailRS
{
	char *detailQtyPtr;
	int count = 0;
	unsigned long number;
	char *tmp;
	money_t amount;

	[self setBuffer: aBuffer];

	number = [aDepositRS getLongValue: "NUMBER"];

	/*
		Number Int 4 Numero de deposito
		DoorId Int 2 Identifica la puerta por la cual se efectuo el deposito.
		CashId Int 2 Identifica el cash 
		DepositType Int 1 Identifica el tipo de deposito.
		OpenTime Datetime 4 Fecha y hora de apertura del deposito.
		CloseTime Datetime 4 Fecha y hora de cierre del deposito.
		UserId Int 4 Identificador de usuario
		EnvelopeNumber Char 15 Numero de sobre (solo para deposito manual)
		RejectedQty Int 2 Cantidad de billetes rechazados durante el deposito.
		DetailQty Int 2 Cantidad de registros de detalle.
		ReferenceId Int 2 Id de reference.
		BankAccountNumber Char 30 Numero de cuenta
		ApplyTo Char 15 Descripcion o codigo de referencia (para ambos tipos de deposito)
		PhotoSize Int 4 Tama�o de foto.
		Photo Char[PhotoSize] PhotoSize Stream de bytes con la foto
	*/
	[self writeLong: number];
	[self writeShort: [aDepositRS getShortValue: "DOOR_ID"]];
	[self writeShort: [aDepositRS getShortValue: "CIM_CASH_ID"]];
	[self writeByte:  [aDepositRS getCharValue: "DEPOSIT_TYPE"]];
	[self writeDateTime: [aDepositRS getDateTimeValue: "OPEN_TIME"]];
	[self writeDateTime: [aDepositRS getDateTimeValue: "CLOSE_TIME"]];
	[self writeLong: [aDepositRS getLongValue: "USER_ID"]];
	[self writeString: [aDepositRS getStringValue: "ENVELOPE_NUMBER" buffer: myTempBuffer] qty: 15]; 
	[self writeShort: [aDepositRS getShortValue: "REJECTED_QTY"]];

	// El detalle lo relleno despues
	detailQtyPtr = myBuffer;
	[self writeShort: 0];	

	[self writeShort: [aDepositRS getShortValue: "REFERENCE_ID"]];
	[self writeString: [aDepositRS getStringValue: "BANK_ACCOUNT_NUMBER" buffer: myTempBuffer] qty: 30];
	[self writeString: [aDepositRS getStringValue: "APPLY_TO" buffer: myTempBuffer] qty: 15];
	
	// Tamano de la foto
	[self writeLong: 0];	/** @todo: enviar la foto */

	// Foto
	
	

	// Calcula y acumula los detalles en primer lugar porque de ahi obtiene
	// la cantidad de detalles y el total del deposito (que no tiene sentido
	// que vaya ni siquiera porque hay un total por moneda o validador que
	// hay que considerar)

	while (![aDepositDetailRS eof] && [aDepositDetailRS getLongValue: "NUMBER"] == number) {

		
		/*
			AcceptorId Int 2 Identificador del dispositivo por el cual se introdujo el valor.
			DepositValueType Int 1 Tipo de valor depositado.
			Qty Int 2 Cantidad depositada
			Amount Money 5 Monto unitario (en el caso de validador de billetes seria equivalente a "denominacion")
			CurrencyId Int 2 Identificador de moneda.
		*/

			[self writeShort: [aDepositDetailRS getShortValue: "ACCEPTOR_ID"]];
			[self writeByte:  [aDepositDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"]];
			[self writeShort: [aDepositDetailRS getShortValue: "QTY"]];

			// Para el tipo de deposito validado en el campo AMOUNT viene la denominacion (unitario)
			// En todos los demas casos viene el importe final
			// El sistema de gestion siempre solicita el importe total por lo tanto tengo que hacer
			// la conversion

			if ([aDepositDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"] == DepositValueType_VALIDATED_CASH) {
				amount = [aDepositDetailRS getMoneyValue: "AMOUNT"] * [aDepositDetailRS getShortValue: "QTY"];
			} else {
				amount = [aDepositDetailRS getMoneyValue: "AMOUNT"];
			}
		
			[self writeMoney: amount];
			[self writeShort: [aDepositDetailRS getShortValue: "CURRENCY_ID"]];

			count++;

		[aDepositDetailRS moveNext];

	}

	// Aca escribo la cantidad de items, ya que no la calculo
	// de antemano sino cuando termino de procesar todo el deposito
	// pero lo tengo que escribir en una posicion anterior
	tmp = myBuffer;
	myBuffer = detailQtyPtr;
	[self writeShort: count];
	myBuffer = tmp;

	return [self getLenInfo];	
}

/**/
- (int) getBagTrackingMode: (id) aDoor
{
	id doorAcceptorSettings;
	id doorAcceptors = [aDoor getAcceptorSettingsList];
	int type = BagTrackingMode_NONE;
	int i;
	int bagTrackingMode;


	//doLog(0, "cantidad de aceptadores =%d\n", [doorAcceptors size]);

	for (i=0; i<[doorAcceptors size]; ++i) {

		doorAcceptorSettings = [doorAcceptors at: i];
	
		if (([doorAcceptorSettings getAcceptorType] == AcceptorType_MAILBOX) && ([[CimGeneralSettings getInstance] getRemoveBagVerification])) {

			if (bagTrackingMode == BagTrackingMode_AUTO) {
				bagTrackingMode = BagTrackingMode_MIXED;
			} else bagTrackingMode = BagTrackingMode_MANUAL;

		}


		if (([doorAcceptorSettings getAcceptorType] == DepositType_AUTO) && ([[CimGeneralSettings getInstance] getBagTracking])) {

			if (bagTrackingMode == BagTrackingMode_MANUAL) {
				bagTrackingMode = BagTrackingMode_MIXED;
			} else bagTrackingMode = BagTrackingMode_AUTO;

		}

	}

	return bagTrackingMode;
}


/**/
- (int) formatExtraction: (char *) aBuffer
		includeExtractionDetails: (BOOL) aIncludeExtractionDetails
		extractions: (ABSTRACT_RECORDSET) aExtractionRS
		extractionDetails: (ABSTRACT_RECORDSET) aExtractionDetailRS
		bagNumber: (char *) aBagNumber
		hasBagTracking: (BOOL) aHasBagTracking
		bagTrackingDetails: (ABSTRACT_RECORDSET) aBagTrackingDetailsRS
{
	char *detailQtyPtr;
	char *bagTrackingQtyPtr;
	int count = 0;
	int countBagTracking = 0;
	unsigned long number;
	char *tmp;
	money_t amount;
	char buffer[51];
	int totalToRead = 0;
	int envelopesToRead = 0;
	id door = NULL;
	COLLECTION doorAcceptors;
	id doorAcceptorSettings;
	int bagTrackingMode;

	[self setBuffer: aBuffer];

	number = [aExtractionRS getLongValue: "NUMBER"];

	/*
		Number Int 4 Numero de extraccion
		DoorId Int 2 Identifica la puerta por la cual se efectuo la extraccion.
		Date Datetime 4 Fecha y hora de realizacion de la extraccion.
		OperatorId Int 4 Identificador del usuario operador.
		CollectorId Int 4 Identificador del usuario recaudador.
		RejectedQty Int 2 Cantidad de billetes rechazados durante el deposito.
		FromDepositNumber Int 4 Numero del primer deposito que incluye esta extraccion
		ToDepositNumber Int 4 Numero del ultimo deposito que incluye esta extraccion.
		BankInfo Char[50] Informacion bancaria
		FromXNumber Int 4 Numero de X desde
    ToXNumber Int 4 Numero de X hasta
		DetailQty Int 2 Cantidad de registros de detalle.
		BagNumber Char[30] Numero de bolsa en la cual colocan los sobres, bolsas o stackers
		BagTrackingDetailQty Int 2 Cantidad de registros de detalle de bag tracking.
		TotalToRead Int 2 Cantidad total de bolsas o cassettes a leer.
		EnvelopesToRead Int 2 Cantidad total de sobres a leer.
		PhotoSize Int 4 Tama�o de foto.
		Photo Char[PhotoSize] PhotoSize Stream de bytes con la foto

	*/

	[self writeLong: number];
	[self writeShort: [aExtractionRS getShortValue: "DOOR_ID"]];
	[self writeDateTime: [aExtractionRS getDateTimeValue: "DATE_TIME"]];
	[self writeLong: [aExtractionRS getLongValue: "OPERATOR_ID"]];
	[self writeLong: [aExtractionRS getLongValue: "COLLECTOR_ID"]];
	[self writeShort: [aExtractionRS getShortValue: "REJECTED_QTY"]];
	
	if ([aExtractionRS getLongValue: "TO_DEPOSIT_NUMBER"] == 0)
		[self writeLong: 0]; 
	else
	  [self writeLong: [aExtractionRS getLongValue: "FROM_DEPOSIT_NUMBER"]];

	if ([aExtractionRS getLongValue: "FROM_DEPOSIT_NUMBER"] == 0)
		[self writeLong: 0]; 
	else
		[self writeLong: [aExtractionRS getLongValue: "TO_DEPOSIT_NUMBER"]];

	/*BANK INFO*/
	[self writeString: "" qty: 50];

	// Si el Numero TO es 0, entonces el From tambien lo mando en 0
	if ([aExtractionRS getLongValue: "TO_CLOSE_NUMBER"] == 0)
		[self writeLong: 0];
	else
		[self writeLong: [aExtractionRS getLongValue: "FROM_CLOSE_NUMBER"]]; // from x

	[self writeLong: [aExtractionRS getLongValue: "TO_CLOSE_NUMBER"]]; // to x

	// El detalle de la extraccion lo relleno despues
	detailQtyPtr = myBuffer;
	[self writeShort: 0];

	/*Bag Number*/
	[self writeString: aBagNumber qty: 30];

	// El detalle de bug tracking lo relleno despues
	bagTrackingQtyPtr = myBuffer;
	[self writeShort: 0];

	// Total To Read (solo lo calculo cuando hay bag tracking)
	if (aHasBagTracking) {
		door = [[CimManager getInstance] getDoorById: [aExtractionRS getShortValue: "DOOR_ID"]];

		if (door) {

			bagTrackingMode = [self getBagTrackingMode: door];

			if (bagTrackingMode == BagTrackingMode_AUTO || bagTrackingMode == BagTrackingMode_MIXED) {
				
				doorAcceptors = [door getAcceptorSettingsList];
				doorAcceptorSettings = [doorAcceptors at: 0];

				totalToRead = [doorAcceptors size];
			}

			if (bagTrackingMode == BagTrackingMode_MANUAL || bagTrackingMode == BagTrackingMode_MIXED) {
				
				envelopesToRead = [[DepositDetailReport getInstance] getTicketsCountByDepositType: [aExtractionRS getLongValue: "FROM_DEPOSIT_NUMBER"]
					toDepositNumber: [aExtractionRS getLongValue: "TO_DEPOSIT_NUMBER"] depositType: DepositType_MANUAL];
			}
		}
	}

	//doLog(0,"totalToread = %d\n", totalToRead);
	//doLog(0,"envelopesToRead = %d\n", envelopesToRead);

	[self writeShort: totalToRead];
	[self writeShort: envelopesToRead];

	[self writeLong: 0];	/** @todo: enviar la foto */
	// aca vendria la foto

	// recorro la cantidad de detalles de la exraccion
	while (![aExtractionDetailRS eof] && [aExtractionDetailRS getLongValue: "NUMBER"] == number) {

		/*
			AcceptorId Int 2 Identificador del dispositivo por el cual se introdujo el valor.
			CashId Int 2 Identificador del cash desde el cual se realizo la extraccion.
			DepositValueType Int 1 Tipo de valor depositado.
			Qty Int 2 Cantidad depositada
			Amount Money 5 Monto unitario (en el caso de validador de billetes seria equivalente a "denominacion")
			CurrencyId Int 2 Identificador de moneda.
		*/

			[self writeShort: [aExtractionDetailRS getShortValue: "ACCEPTOR_ID"]];
			[self writeShort: [aExtractionDetailRS getShortValue: "CIM_CASH_ID"]];
			[self writeByte:  [aExtractionDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"]];
			[self writeShort: [aExtractionDetailRS getShortValue: "QTY"]];

			// Para el tipo de deposito validado en el campo AMOUNT viene la denominacion (unitario)
			// En todos los demas casos viene el importe final
			// El sistema de gestion siempre solicita el importe total por lo tanto tengo que hacer
			// la conversion
			if ([aExtractionDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"] == DepositValueType_VALIDATED_CASH) {
				amount = [aExtractionDetailRS getMoneyValue: "AMOUNT"] * [aExtractionDetailRS getShortValue: "QTY"];
			} else {
				amount = [aExtractionDetailRS getMoneyValue: "AMOUNT"];
			}

			[self writeMoney: amount];

			[self writeShort: [aExtractionDetailRS getShortValue: "CURRENCY_ID"]];

		count++;

		[aExtractionDetailRS moveNext];

	}

	// recorro la canidad de bug tracking y lo inserto en el archivo
	if (aHasBagTracking) {

		while (![aBagTrackingDetailsRS eof] && [aBagTrackingDetailsRS getLongValue: "EXTRACTION_NUMBER"] == number) {
	
			/*
				Number Char[30] 2 numero escaneado
				Type Int 1 tipo (bolsa o stacker)
			*/
			if ([aBagTrackingDetailsRS getLongValue: "PARENT_ID"] > 0) {
				//doLog(0,"number= %s\n", [aBagTrackingDetailsRS getStringValue: "NUMBER" buffer: buffer]);
				//doLog(0,"type = %d\n", [aBagTrackingDetailsRS getCharValue: "TYPE"]);
				[self writeString: [aBagTrackingDetailsRS getStringValue: "NUMBER" buffer: buffer] qty: 30];
				[self writeByte: [aBagTrackingDetailsRS getCharValue: "TYPE"]];
				countBagTracking++;
			}
			[aBagTrackingDetailsRS moveNext];
		}
	}


	// completo la cantidad de detalles de la extraccion
	tmp = myBuffer;
	myBuffer = detailQtyPtr;
	
	[self writeShort: count];
	myBuffer = tmp;

	// completo la cantidad de detalles del bug tracking
	tmp = myBuffer;
	myBuffer = bagTrackingQtyPtr;
	
	[self writeShort: countBagTracking];
	myBuffer = tmp;

	return [self getLenInfo];	
}

/**/
- (int) formatZClose: (char *) aBuffer
		includeZCloseDetails: (BOOL) aIncludeZCloseDetails
		zclose: (ABSTRACT_RECORDSET) aZCloseRS
{
	unsigned long number;

	[self setBuffer: aBuffer];

	number = [aZCloseRS getLongValue: "NUMBER"];

	/*
		Number Int 4 Numero de zclose
		OpenTime Datetime 4 Fecha y hora de apertura del zclose.
		CloseTime Datetime 4 Fecha y hora de cierre del zclose.		
		UserId Int 4 Identificador de usuario
    RejectedQty Int 2 Cantidad de billetes rechazados durante el zclose.
		FromXNumber Int 4 Numero de X desde
    ToXNumber Int 4 Numero de X hasta
		FromDepositNumber Int 4 Numero de deposito desde
    ToDepositNumber Int 4 Numero de deposito hasta
	*/
	
	[self writeLong: number];
	[self writeDateTime: [aZCloseRS getDateTimeValue: "OPEN_TIME"]];
	[self writeDateTime: [aZCloseRS getDateTimeValue: "CLOSE_TIME"]];
	[self writeLong: [aZCloseRS getLongValue: "USER_ID"]];
	[self writeShort: [aZCloseRS getShortValue: "REJECTED_QTY"]];

	// Si el Numero TO es 0, entonces el From tambien lo mando en 0
	if ([aZCloseRS getLongValue: "TO_CLOSE_NUMBER"] == 0)
		[self writeLong: 0];
	else
		[self writeLong: [aZCloseRS getLongValue: "FROM_CLOSE_NUMBER"]]; // from x

	[self writeLong: [aZCloseRS getLongValue: "TO_CLOSE_NUMBER"]]; // to x

	// Si el Numero TO es 0, entonces el From tambien lo mando en 0
	if ([aZCloseRS getLongValue: "TO_DEPOSIT_NUMBER"] == 0)
		[self writeLong: 0];
	else
		[self writeLong: [aZCloseRS getLongValue: "FROM_DEPOSIT_NUMBER"]];

	[self writeLong: [aZCloseRS getLongValue: "TO_DEPOSIT_NUMBER"]];
  
	return [self getLenInfo];	
}

/**/
- (int) formatXClose: (char *) aBuffer
		includeXCloseDetails: (BOOL) aIncludeXCloseDetails
		xclose: (ABSTRACT_RECORDSET) aXCloseRS
{
	unsigned long number;
	money_t amount;
	id xCloseDetail;	
	COLLECTION xcDetails;
	int i;
	ZCLOSE cashClose;

	[self setBuffer: aBuffer];
	number = [aXCloseRS getLongValue: "NUMBER"];
	/*
		Number Int 4 Numero de xclose
		OpenTime Datetime 4 Fecha y hora de apertura del xclose.
		CloseTime Datetime 4 Fecha y hora de cierre del xclose.		
		UserId Int 4 Identificador de usuario
    RejectedQty Int 2 Cantidad de billetes rechazados durante el xclose.
		FromDepositNumber Int 4 Numero de deposito desde
    ToDepositNumber Int 4 Numero de deposito hasta
    CashId Int 2 Identificador del cash desde el cual se realizo el xClose.
    DetailQty Int 2 Cantidad de registros de detalle.
	*/
	[self writeLong: number];
	[self writeDateTime: [aXCloseRS getDateTimeValue: "OPEN_TIME"]];
	[self writeDateTime: [aXCloseRS getDateTimeValue: "CLOSE_TIME"]];
	[self writeLong: [aXCloseRS getLongValue: "USER_ID"]];
	[self writeShort: [aXCloseRS getShortValue: "REJECTED_QTY"]];

	// Si el Numero TO es 0, entonces el From tambien lo mando en 0
	if ([aXCloseRS getLongValue: "TO_DEPOSIT_NUMBER"] == 0)
		[self writeLong: 0];		
	else
		[self writeLong: [aXCloseRS getLongValue: "FROM_DEPOSIT_NUMBER"]];

	[self writeLong: [aXCloseRS getLongValue: "TO_DEPOSIT_NUMBER"]];

	[self writeShort: [aXCloseRS getShortValue: "CIM_CASH_ID"]];

	cashClose = [[ZCloseManager getInstance] loadCashCloseById: number];

	if (cashClose == NULL) {
		[self writeShort: 0];
		return [self getLenInfo];
	} 

	xcDetails = [cashClose getZCloseDetails];
	[self writeShort: [xcDetails size]];


	for (i = 0; i < [xcDetails size]; ++i) {

		xCloseDetail = [xcDetails at: i];

		  //AcceptorId Int 2 Identificador del dispositivo por el cual se introdujo el valor.		
		  //DepositValueType Int 1 Tipo de valor depositado.
		  //Qty Int 2 Cantidad depositada
		  //Amount Money 5 Monto total
		  //CurrencyId Int 2 Identificador de moneda.

		[self writeShort: [[xCloseDetail getAcceptorSettings] getAcceptorId]];
		[self writeByte:  [xCloseDetail getDepositValueType]];
		[self writeShort: [xCloseDetail getQty]];
		amount = [xCloseDetail getAmount];
		[self writeMoney: amount];
		[self writeShort: [[xCloseDetail getCurrency] getCurrencyId]];

	}

	return [self getLenInfo];	
}


/**/
- (int) formatUser: (char *) aBuffer
		user: (id) aUser
{
	/*
		UserId Int 2
		ProfileId Int 2
		LoginName Char 10
		Name Char 21
    SurName Char 21
		BankAccountNumber Char 21
    Active Int 1
    TemporaryPassword Int 1
    LastLoginDateTime Datetime 4
    LastChangePasswordDateTime Datetime 4
    LoginMethod Int 1
    Language Int 1
    EnrollDateTime Datetime 4
    Key Char 19
    Deleted Int 1
	*/

	[self setBuffer: aBuffer];

	[self writeShort: [aUser getUserId]];
	[self writeShort: [aUser getUProfileId]];
	[self writeString: [aUser getLoginName] qty: 10];
	[self writeString: [aUser getUName] qty: 21];
	[self writeString: [aUser getUSurname] qty: 21];
	[self writeString: [aUser getBankAccountNumber] qty: 21];
	[self writeByte: [aUser isActive]];
	[self writeByte: [aUser isTemporaryPassword]];
	[self writeDateTime: [aUser getLastLoginDateTime]];
	[self writeDateTime: [aUser getLastChangePasswordDateTime]];
	[self writeByte: [aUser getLoginMethod]];
	[self writeByte: [aUser getLanguage]];
	[self writeDateTime: [aUser getEnrollDateTime]];
	[self writeString: [aUser getKey] qty: 19];
	[self writeByte: [aUser isDeleted]];

	return [self getLenInfo];
}

@end
