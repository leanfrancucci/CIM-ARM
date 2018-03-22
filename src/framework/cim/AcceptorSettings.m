#include "AcceptorSettings.h"
#include "Persistence.h"
#include "AcceptorDAO.h"
#include "SafeBoxHAL.h"
#include "Audit.h"
#include "CimManager.h"
#include "Box.h"
#include "ResourceStringDefs.h"


@implementation AcceptorSettings



/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myAcceptedDepositValues = [Collection new];
	myAcceptorId = 0;
	myAcceptorType = AcceptorType_UNDEFINED;
	*myAcceptorName = '\0';
	myBrand = BrandType_UNDEFINED;
	*myModel = '\0';
	myProtocol = 1;
	myHardwareId = 0;
	myStackerSize = 0;
	myStackerWarningSize = 0;
	myBaudRate = 5;
	myDataBits = 0;
	myParity = 1;
	myStopBits = 0;
	myFlowControl = 0;
	myComPortNumber = 1;
	*mySerialNumber = '\0';
	myStartTimeOut = 0;
	myEchoDisable = FALSE;
	myIsDisabled = FALSE;

	return self;
}

/**/
- (CURRENCY) getDefaultCurrency
{
	if ([myAcceptedDepositValues size] > 0)
		if ([[[myAcceptedDepositValues at: 0] getAcceptedCurrencies] size] > 0)
			return [[[[myAcceptedDepositValues at: 0] getAcceptedCurrencies] at: 0] getCurrency];

	return NULL;
}

/**/
- (void) setComPortNumber: (int) aNumber { myComPortNumber = aNumber; }
- (int) getComPortNumber { return myComPortNumber; }

/**/
- (void) setAcceptorId: (int) aValue { myAcceptorId = aValue; }
- (int) getAcceptorId { return myAcceptorId; }

/**/
- (void) setAcceptorType: (AcceptorType) aValue { myAcceptorType = aValue; }
- (AcceptorType) getAcceptorType { return myAcceptorType; }

/**/
- (void) setAcceptorName: (char*) aValue { stringcpy(myAcceptorName, aValue); }
- (char*) getAcceptorName { return myAcceptorName; }

/**/
- (void) setAcceptorBrand: (BrandType) aValue { myBrand = aValue; }
- (BrandType) getAcceptorBrand { return myBrand; }

/**/
- (void) setAcceptorModel: (char*) aValue { stringcpy(myModel, aValue); }
- (char*) getAcceptorModel { return myModel; }

/**/
- (void) setAcceptorProtocol: (int) aValue { myProtocol = aValue; }
- (int) getAcceptorProtocol { return myProtocol; }

/**/
- (void) setAcceptorSerialNumber: (char*) aValue { stringcpy(mySerialNumber, aValue); }
- (char*) getAcceptorSerialNumber { return mySerialNumber; }

/**/
- (void) setAcceptorHardwareId: (int) aValue { myHardwareId = aValue; }
- (int) getAcceptorHardwareId { return myHardwareId; }

/**/
- (void) setStackerSize: (int) aValue { myStackerSize = aValue; }
- (int) getStackerSize { return myStackerSize; }

/**/
- (void) setStackerWarningSize: (int) aValue { myStackerWarningSize = aValue; }
- (int) getStackerWarningSize { return myStackerWarningSize; }

- (void) setDoor: (DOOR) aValue { myDoor = aValue; }
- (DOOR) getDoor { return myDoor; }

/**/
- (void) setAcceptorBaudRate: (BaudRateType) aValue { myBaudRate = aValue; }
- (BaudRateType) getAcceptorBaudRate { return myBaudRate; }

/**/
- (void) setAcceptorDataBits: (int) aValue { myDataBits = aValue; }
- (int) getAcceptorDataBits { return myDataBits; }

/**/
- (void) setAcceptorParity: (int) aValue { myParity = aValue; }
- (int) getAcceptorParity { return myParity; } 

/**/
- (void) setAcceptorStopBits: (int) aValue { myStopBits = aValue; }
- (int) getAcceptorStopBits { return myStopBits; }

/**/
- (void) setAcceptorFlowControl: (int) aValue { myFlowControl = aValue; }
- (int) getAcceptorFlowControl { return myFlowControl; }

/**/
- (void) setDeleted: (BOOL) aValue 
{ 

	hasToActivateAcceptorByBox = FALSE;
	hasToInactivateAcceptorByBox = FALSE;

	if ((myDeleted == TRUE) && (aValue == FALSE)) {
		/*Debe activar el acceptor by box */
		hasToActivateAcceptorByBox = TRUE;
	}

	if ((myDeleted == FALSE) && (aValue == TRUE)) {
		/*Debe desactivar el acceptor by box */
		hasToInactivateAcceptorByBox = TRUE;
	}
	
	myDeleted = aValue; 
}

/**/
- (BOOL) isDeleted { return myDeleted; }


//- (void) setStartTimeOut: (int) aValue {myStartTimeOut = aValue;}

//Por el momento se manda esta valor
- (int) getStartTimeOut {return 4;}

//- (void) setEchoDisable: (BOOL) aValue {myEchoDisable = aValue;}

//Solo se habilita en el caso que sea ProtocolType_CCTAL
- (BOOL) isEchoDisable {
	if (myProtocol == ProtocolType_CCTALK)
		return TRUE;
	else
		return FALSE;
	}


/**/
- (void) addAcceptedDepositValue: (ACCEPTED_DEPOSIT_VALUE) aValue
{
	[myAcceptedDepositValues add: aValue];
}

/**/
- (void) removeAcceptedDepositValue: (int) aValue
{
	int i = 0;
	
	for (i=0; i<=[myAcceptedDepositValues size]-1; ++i) 
		if ([ [myAcceptedDepositValues at: i] getDepositValueType] == aValue) {
			[myAcceptedDepositValues removeAt: i];
			return;
		}
}

/**/
- (COLLECTION) getAcceptedDepositValues { return myAcceptedDepositValues; }

/**/
- (ACCEPTED_DEPOSIT_VALUE) getAcceptedDepositValueByType: (int) aType
{
	int i;

	for (i=0; i<[myAcceptedDepositValues size]; ++i)
		if ([[myAcceptedDepositValues at: i] getDepositValueType] == aType) return [myAcceptedDepositValues at: i];

	return NULL;
}

/**/
- (void) applyChanges
{
	id dao = [[Persistence getInstance] getAcceptorDAO];		

	[dao store: self];

	if (hasToActivateAcceptorByBox)
			[[[CimManager getInstance] getCim] addAcceptorByBox: 1 acceptorId: myAcceptorId];
	
	if (hasToInactivateAcceptorByBox)
		[[[CimManager getInstance] getCim] removeAcceptorByBox: 1 acceptorId: myAcceptorId];

}

/**/
- (void) storeDenomination: (int) aDepositValueType acceptorId: (int) anAccpetorId currencyId: (int) aCurrencyId denomination: (DENOMINATION) aDenomination
{
	id dao = [[Persistence getInstance] getAcceptorDAO];		

	[dao storeDenomination: aDepositValueType acceptorId: anAccpetorId currencyId: aCurrencyId denomination: aDenomination];
}

/**/
- (void) addDepositValueType: (int) aDepositValueType
{
	id acceptedDepositValue;
	id dao = [[Persistence getInstance] getAcceptorDAO];		

	TRY
	
		[dao addDepositValueType: myAcceptorId depositValueType: aDepositValueType];
		
		acceptedDepositValue = [AcceptedDepositValue new];
		[acceptedDepositValue setDepositValueType: aDepositValueType];
		// carga los currencies (divisas) de este valor aceptado
		[dao loadAcceptedCurrencies: acceptedDepositValue acceptorId: myAcceptorId];

		// agrega el deposito aceptado al acceptor
		[self addAcceptedDepositValue: acceptedDepositValue];

	CATCH

		RETHROW();

	END_TRY
}

/**/
- (void) removeDepositValueType: (int) aDepositValueType
{
	id dao = [[Persistence getInstance] getAcceptorDAO];		

	TRY
	
		[dao removeDepositValueType: myAcceptorId depositValueType: aDepositValueType];
		
		// agrega el deposito aceptado al acceptor
		[self removeAcceptedDepositValue: aDepositValueType];

	CATCH

		RETHROW();

	END_TRY

}

/**/
- (STR) str
{
	return myAcceptorName;
}

/**/
- (void) verifySerialNumberChange
{
	char buffer[60];
	AUDIT audit;
	char buf[50];
  char bufBloque1[50];
	char bufBloque2[50];


	if (myAcceptorType == AcceptorType_VALIDATOR) {

	 [SafeBoxHAL getBillValidatorVersion: myHardwareId buffer: buffer];

	/*doLog(0,"****************************************************************\n");
	doLog(0,"physical serial number = %s \n", buffer);
	doLog(0," serial number = %s \n", mySerialNumber);
	doLog(0,"****************************************************************\n");
*/
	 // Si no devuelve numero de serie no hago nada
	 if (strlen(buffer) == 0) return;


		// Si esta vacio lo inicializa y lo almacena
	 if (strcmp(mySerialNumber,"") == 0) {
			stringcpy(mySerialNumber, buffer);
			[self applyChanges];
	 }

	 // Los numeros de seria cambiaron se debe almacenar y emitir una advertencia
	 if (strcmp(mySerialNumber, buffer) != 0) {
         // ************************* logcoment
         //doLog(0,"El numero de serie del validador %d es diferente y lo guardo \n", myHardwareId);
		stringcpy(mySerialNumber, buffer);
		[self applyChanges];

		//[Audit auditEventCurrentUser: EVENT_ACCEPTOR_SERIAL_NUMBER_CHANGE additional: "" station: myAcceptorId logRemoteSystem: FALSE];

		audit = [[Audit new] initAuditWithCurrentUser: EVENT_ACCEPTOR_SERIAL_NUMBER_CHANGE  
						additional: "" station: myAcceptorId logRemoteSystem: FALSE];
    
    //Grabo en las auditorias la version firm del validador actualizado
		buf[0]='\0';
 		stringcpy(buf,mySerialNumber);

        //************************* logcoment
        //doLog(0,"\n*********%s*********\n",mySerialNumber);

		if (strlen(buf) > 0){
			bufBloque1[0] = '\0';
			bufBloque2[0] = '\0';
        		  
			if (strlen(buf) > 19){
				memcpy( bufBloque1, buf, 19 );
				bufBloque1[19] = '\0';
          		  
				memcpy( bufBloque2, &buf[19], (strlen(buf) - 19) );
				bufBloque2[strlen(buf)-19] = '\0';
       	}else 
					strcpy(bufBloque1, buf);

			[audit logChangeAsString: RESID_Acceptor_VERSION oldValue: "" newValue: bufBloque1];                 
                
			if (strlen(bufBloque2) > 0){  
				[audit logChangeAsString: RESID_BLANK oldValue: "" newValue: bufBloque2];
			}
    }
		else{
			[audit logChangeAsString: RESID_Acceptor_VERSION oldValue: "" newValue: getResourceStringDef(RESID_NOT_AVAILABLE, "NO DISPONIBLE")];
		}

		[audit saveAudit];  
  	[audit free];	

		if (mySerialNumberChangeListener) 
			[mySerialNumberChangeListener notifySerialNumberChange: myAcceptorId];

	 }

	}

}

/**/
- (void) setSerialNumberChangeListener: (id) aListener
{
	mySerialNumberChangeListener = aListener;
}

/**/
- (void) setDisabled: (BOOL) aValue { myIsDisabled = aValue; }
- (BOOL) isDisabled { return myIsDisabled; }

/**/
#ifdef __DEBUG_CIM
- (void) debug
{
	static char *acceptorTypes[] = {"No definido", "Validador", "Buzon"};
	int i;

	doLog(0,"*******************************************************************************\n");
	doLog(0,"Device Id = %d\n", myAcceptorId);
	doLog(0,"Type      = %s\n", acceptorTypes[myAcceptorType]);
	doLog(0,"Door id   = %d\n", [myDoor getDoorId]);
	doLog(0,"Despositos aceptados\n");
	doLog(0,"Stacker size = %d\n", myStackerSize);
	doLog(0,"Stacker Warning size = %d\n", myStackerWarningSize);
	for (i = 0; i < [myAcceptedDepositValues size]; ++i) {
		[[myAcceptedDepositValues at: i] debug];
	}
	doLog(0,"*******************************************************************************\n");
}

#endif

@end
