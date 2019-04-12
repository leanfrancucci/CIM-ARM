#include "BoxModel.h"
#include "CimExcepts.h"
#include "CimManager.h"
#include "Persistence.h"
#include "Audit.h"

@implementation BoxModel

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myPhisicalModel = -1;
	myVal1Model = -1;
	myVal2Model = -1;

	return self;
}

/**/
- (void) setPhisicalModel: (PhisicalModel) aValue
{
	myPhisicalModel = aValue;
}


- (PhisicalModel) getPhisicalModel
{
	return myPhisicalModel;
}


/**/
- (void) setVal1Model: (ValidatorModel) aValue
{
	myVal1Model = aValue;
}

- (ValidatorModel) getVal1Model
{
	return myVal1Model;
}

/**/
- (void) setVal2Model: (ValidatorModel) aValue
{
	myVal2Model = aValue;
}

- (ValidatorModel) getVal2Model
{
	 return myVal2Model;
}

/**/
- (void) setDoor: (id) aDoor deleted: (BOOL) aDeleted electronicLock: (BOOL) anElectronicLock outerDoor: (id) anOuterDoor
{
	[aDoor setDeleted: aDeleted];
	[aDoor setHasElectronicLock: anElectronicLock];
	if (anOuterDoor) {
		[aDoor setBehindDoorId: [anOuterDoor getDoorId]];
		[aDoor setOuterDoor: anOuterDoor];
	} else {
		[aDoor setBehindDoorId: 0];
		[aDoor setOuterDoor: NULL];
	}
	[aDoor applyChanges];
}

/**/
- (void) setAcceptor: (id) anAcceptorSett door: (id) aDoor deleted: (BOOL) aDeleted disabled: (BOOL) aDisabled
{
	TRY
		[anAcceptorSett setDoor: aDoor];
		[anAcceptorSett setDeleted: aDeleted];
		[anAcceptorSett setDisabled: aDisabled];
		[anAcceptorSett applyChanges];
	CATCH
	END_TRY
}

/**/
- (void) setAcceptorModel: (id) acceptorSett brand: (int) aBrand model: (char *) aModel parity: (int) aParity stopBits: (int) aStopBits baudRate: (int) aBaudRate protocol: (int) aProtocol dataBits: (int) aDataBits
{
	[acceptorSett setAcceptorBrand: aBrand];
	[acceptorSett setAcceptorModel: aModel];
	[acceptorSett setAcceptorParity: aParity]; // 1 = par / 0 = impar
	[acceptorSett setAcceptorStopBits: aStopBits];
	[acceptorSett setAcceptorBaudRate: aBaudRate];
	[acceptorSett setAcceptorProtocol: aProtocol];
	[acceptorSett setAcceptorDataBits: aDataBits];
	[acceptorSett applyChanges];
}

/**/
- (void) save
{
	COLLECTION doors = NULL;
	id door = NULL;
	COLLECTION acceptorSettingsList = NULL;
	id acceptorSett = NULL;
	id doorVal = NULL;
	id doorMan = NULL;
	id box = NULL;
	COLLECTION cimCashs = NULL;
	int i;
	int count;
	int cashValId;
	int cashManId;
	ValidatorModel model = -1;
	id cim;
	char strCashVal[21];
	char strCashMan[21];

	cim = [[CimManager getInstance] getCim];

	strCashVal[0] = '\0';
	strCashMan[0] = '\0';
	strcpy(strCashVal, "Cash Val");
	strcpy(strCashMan, "Cash Manual");

	doorVal = [cim getDoorById: 1];
	doorMan = [cim getDoorById: 2];

	doors = [cim getDoors];
	acceptorSettingsList = [cim getAcceptorSettings];

	// solo almaceno el modelo fisico si NO hay movimientos realizados.
	if (![cim hasMovements]) {

		// elimino los cash existentes
		cimCashs = [cim getCimCashs];
		if (cimCashs) {
			count = [cimCashs size];
			for (i=0; i<count; ++i) {
				[[cimCashs at: 0] removeAllAcceptorSettings];
				[cim removeCashBox: [[cimCashs at: 0] getCimCashId]];
			}
		}
		
		// almaceno modelo fisico ****************
		switch (myPhisicalModel) {
		
			case PhisicalModel_Box2ED2V1M:
					// seteo las puertas
					for (i = 0; i < [doors size]; ++i) {
						door = [doors at: i];
						[self setDoor: door deleted: FALSE electronicLock: TRUE outerDoor: NULL];
					}
		
					// vuelvo a crear los cash de acuerdo al modelo elegido
					cashValId = [cim addCashBox: strCashVal doorId: [doorVal getDoorId] depositType: DepositType_AUTO];
					cashManId = [cim addCashBox: strCashMan doorId: [doorMan getDoorId] depositType: DepositType_MANUAL];
		
					// seteo los acceptors
					for (i = 0; i < [acceptorSettingsList size]; ++i) {
						acceptorSett = [acceptorSettingsList at: i];
						if ([acceptorSett getAcceptorType] == AcceptorType_VALIDATOR) {
							[self setAcceptor: acceptorSett door: doorVal deleted: FALSE disabled: FALSE];
							[cim addAcceptorByCash: cashValId acceptorId: [acceptorSett getAcceptorId]];
						} else {
							[self setAcceptor: acceptorSett door: doorMan deleted: FALSE disabled: FALSE];
							[cim addAcceptorByCash: cashManId acceptorId: [acceptorSett getAcceptorId]];
						}
					}
		
				break;
			case PhisicalModel_Box2ED1V1M:
					// seteo las puertas
					for (i = 0; i < [doors size]; ++i) {
						door = [doors at: i];
						[self setDoor: door deleted: FALSE electronicLock: TRUE outerDoor: NULL];
					}
		
					// vuelvo a crear los cash de acuerdo al modelo elegido
					cashValId = [cim addCashBox: strCashVal doorId: [doorVal getDoorId] depositType: DepositType_AUTO];
					cashManId = [cim addCashBox: strCashMan doorId: [doorMan getDoorId] depositType: DepositType_MANUAL];
		
					// seteo los acceptors
					for (i = 0; i < [acceptorSettingsList size]; ++i) {
						acceptorSett = [acceptorSettingsList at: i];
						if ([acceptorSett getAcceptorType] == AcceptorType_VALIDATOR) {
							if ([acceptorSett getAcceptorId] == 1) {
								[self setAcceptor: acceptorSett door: doorVal deleted: FALSE disabled: FALSE];
								[cim addAcceptorByCash: cashValId acceptorId: [acceptorSett getAcceptorId]];
							} else [self setAcceptor: acceptorSett door: doorVal deleted: TRUE disabled: TRUE];
						} else {
							[self setAcceptor: acceptorSett door: doorMan deleted: FALSE disabled: FALSE];
							[cim addAcceptorByCash: cashManId acceptorId: [acceptorSett getAcceptorId]];
						}
					}
		
				break;
			case PhisicalModel_Box2EDI2V1M:
					// seteo las puertas
					for (i = 0; i < [doors size]; ++i) {
						door = [doors at: i];
						if ([door getDoorId] == 1)
							[self setDoor: door deleted: FALSE electronicLock: TRUE outerDoor: NULL];
						else
							[self setDoor: door deleted: FALSE electronicLock: TRUE outerDoor: doorVal];
					}
		
					// vuelvo a crear los cash de acuerdo al modelo elegido
					cashValId = [cim addCashBox: strCashVal doorId: [doorVal getDoorId] depositType: DepositType_AUTO];
					cashManId = [cim addCashBox: strCashMan doorId: [doorMan getDoorId] depositType: DepositType_MANUAL];
		
					// seteo los acceptors
					for (i = 0; i < [acceptorSettingsList size]; ++i) {
						acceptorSett = [acceptorSettingsList at: i];
						if ([acceptorSett getAcceptorType] == AcceptorType_VALIDATOR) {
							[self setAcceptor: acceptorSett door: doorVal deleted: FALSE disabled: FALSE];
							[cim addAcceptorByCash: cashValId acceptorId: [acceptorSett getAcceptorId]];
						} else {
							[self setAcceptor: acceptorSett door: doorMan deleted: FALSE disabled: FALSE];
							[cim addAcceptorByCash: cashManId acceptorId: [acceptorSett getAcceptorId]];
						}
					}
		
				break;
			case PhisicalModel_Box2EDI1V1M:
					// seteo las puertas
					for (i = 0; i < [doors size]; ++i) {
						door = [doors at: i];
						if ([door getDoorId] == 1)
							[self setDoor: door deleted: FALSE electronicLock: TRUE outerDoor: NULL];
						else
							[self setDoor: door deleted: FALSE electronicLock: TRUE outerDoor: doorVal];
					}
		
					// vuelvo a crear los cash de acuerdo al modelo elegido
					cashValId = [cim addCashBox: strCashVal doorId: [doorVal getDoorId] depositType: DepositType_AUTO];
					cashManId = [cim addCashBox: strCashMan doorId: [doorMan getDoorId] depositType: DepositType_MANUAL];
		
					// seteo los acceptors
					for (i = 0; i < [acceptorSettingsList size]; ++i) {
						acceptorSett = [acceptorSettingsList at: i];
						if ([acceptorSett getAcceptorType] == AcceptorType_VALIDATOR) {
							if ([acceptorSett getAcceptorId] == 1) {
								[self setAcceptor: acceptorSett door: doorVal deleted: FALSE disabled: FALSE];
								[cim addAcceptorByCash: cashValId acceptorId: [acceptorSett getAcceptorId]];
							} else [self setAcceptor: acceptorSett door: doorVal deleted: TRUE disabled: TRUE];
						} else {
							[self setAcceptor: acceptorSett door: doorMan deleted: FALSE disabled: FALSE];
							[cim addAcceptorByCash: cashManId acceptorId: [acceptorSett getAcceptorId]];
						}
					}
		
				break;

			case PhisicalModel_Box1ED2V1M:
					// seteo las puertas
					for (i = 0; i < [doors size]; ++i) {
						door = [doors at: i];
						if ([door getDoorId] == 1)
							[self setDoor: door deleted: FALSE electronicLock: TRUE outerDoor: NULL];
						else
							[self setDoor: door deleted: TRUE electronicLock: TRUE outerDoor: NULL];
					}
		
					// vuelvo a crear los cash de acuerdo al modelo elegido
					cashValId = [cim addCashBox: strCashVal doorId: [doorVal getDoorId] depositType: DepositType_AUTO];
					cashManId = [cim addCashBox: strCashMan doorId: [doorVal getDoorId] depositType: DepositType_MANUAL];
		
					// seteo los acceptors
					for (i = 0; i < [acceptorSettingsList size]; ++i) {
						acceptorSett = [acceptorSettingsList at: i];
						[self setAcceptor: acceptorSett door: doorVal deleted: FALSE disabled: FALSE];
						if ([acceptorSett getAcceptorType] == AcceptorType_VALIDATOR)
							[cim addAcceptorByCash: cashValId acceptorId: [acceptorSett getAcceptorId]];
						else [cim addAcceptorByCash: cashManId acceptorId: [acceptorSett getAcceptorId]];
					}

				break;

			case PhisicalModel_Box1ED1V1M:
					// seteo las puertas
					for (i = 0; i < [doors size]; ++i) {
						door = [doors at: i];
						if ([door getDoorId] == 1)
							[self setDoor: door deleted: FALSE electronicLock: TRUE outerDoor: NULL];
						else
							[self setDoor: door deleted: TRUE electronicLock: TRUE outerDoor: NULL];
					}
		
					// vuelvo a crear los cash de acuerdo al modelo elegido
					cashValId = [cim addCashBox: strCashVal doorId: [doorVal getDoorId] depositType: DepositType_AUTO];
					cashManId = [cim addCashBox: strCashMan doorId: [doorVal getDoorId] depositType: DepositType_MANUAL];
		
					// seteo los acceptors
					for (i = 0; i < [acceptorSettingsList size]; ++i) {
						acceptorSett = [acceptorSettingsList at: i];
						if ([acceptorSett getAcceptorType] == AcceptorType_VALIDATOR) {
							if ([acceptorSett getAcceptorId] == 1) {
								[self setAcceptor: acceptorSett door: doorVal deleted: FALSE disabled: FALSE];
								[cim addAcceptorByCash: cashValId acceptorId: [acceptorSett getAcceptorId]];
							} else [self setAcceptor: acceptorSett door: doorVal deleted: TRUE disabled: TRUE];
						} else {
							[self setAcceptor: acceptorSett door: doorVal deleted: FALSE disabled: FALSE];
							[cim addAcceptorByCash: cashManId acceptorId: [acceptorSett getAcceptorId]];
						}
					}
				break;

			case PhisicalModel_Box1ED1M:
					// seteo las puertas
					for (i = 0; i < [doors size]; ++i) {
						door = [doors at: i];
						if ([door getDoorId] == 1)
							[self setDoor: door deleted: TRUE electronicLock: TRUE outerDoor: NULL];
						else
							[self setDoor: door deleted: FALSE electronicLock: TRUE outerDoor: NULL];
					}
		
					// vuelvo a crear los cash de acuerdo al modelo elegido
					cashManId = [cim addCashBox: strCashMan doorId: [doorMan getDoorId] depositType: DepositType_MANUAL];
		
					// seteo los acceptors
					for (i = 0; i < [acceptorSettingsList size]; ++i) {
						acceptorSett = [acceptorSettingsList at: i];
						if ([acceptorSett getAcceptorType] == AcceptorType_VALIDATOR) {
							[self setAcceptor: acceptorSett door: doorVal deleted: TRUE disabled: TRUE];
						} else {
							[self setAcceptor: acceptorSett door: doorMan deleted: FALSE disabled: FALSE];
							[cim addAcceptorByCash: cashManId acceptorId: [acceptorSett getAcceptorId]];
						}
					}
		
				break;
			case PhisicalModel_Box1D2V1M:
					// seteo las puertas
					for (i = 0; i < [doors size]; ++i) {
						door = [doors at: i];
						if ([door getDoorId] == 1)
							[self setDoor: door deleted: FALSE electronicLock: FALSE outerDoor: NULL];
						else
							[self setDoor: door deleted: TRUE electronicLock: FALSE outerDoor: NULL];
					}
		
					// vuelvo a crear los cash de acuerdo al modelo elegido
					cashValId = [cim addCashBox: strCashVal doorId: [doorVal getDoorId] depositType: DepositType_AUTO];
					cashManId = [cim addCashBox: strCashMan doorId: [doorVal getDoorId] depositType: DepositType_MANUAL];
		
					// seteo los acceptors
					for (i = 0; i < [acceptorSettingsList size]; ++i) {
						acceptorSett = [acceptorSettingsList at: i];
						[self setAcceptor: acceptorSett door: doorVal deleted: FALSE disabled: FALSE];
						if ([acceptorSett getAcceptorType] == AcceptorType_VALIDATOR)
							[cim addAcceptorByCash: cashValId acceptorId: [acceptorSett getAcceptorId]];
						else [cim addAcceptorByCash: cashManId acceptorId: [acceptorSett getAcceptorId]];
					}
		
				break;
			case PhisicalModel_Box1D1V1M:
					// seteo las puertas
					for (i = 0; i < [doors size]; ++i) {
						door = [doors at: i];
						if ([door getDoorId] == 1)
							[self setDoor: door deleted: FALSE electronicLock: FALSE outerDoor: NULL];
						else
							[self setDoor: door deleted: TRUE electronicLock: FALSE outerDoor: NULL];
					}
		
					// vuelvo a crear los cash de acuerdo al modelo elegido
					cashValId = [cim addCashBox: strCashVal doorId: [doorVal getDoorId] depositType: DepositType_AUTO];
					cashManId = [cim addCashBox: strCashMan doorId: [doorVal getDoorId] depositType: DepositType_MANUAL];
		
					// seteo los acceptors
					for (i = 0; i < [acceptorSettingsList size]; ++i) {
						acceptorSett = [acceptorSettingsList at: i];
						if ([acceptorSett getAcceptorType] == AcceptorType_VALIDATOR) {
							if ([acceptorSett getAcceptorId] == 1) {
								[self setAcceptor: acceptorSett door: doorVal deleted: FALSE disabled: FALSE];
								[cim addAcceptorByCash: cashValId acceptorId: [acceptorSett getAcceptorId]];
							} else [self setAcceptor: acceptorSett door: doorVal deleted: TRUE disabled: TRUE];
						} else {
							[self setAcceptor: acceptorSett door: doorVal deleted: FALSE disabled: FALSE];
							[cim addAcceptorByCash: cashManId acceptorId: [acceptorSett getAcceptorId]];
						}
					}
		
				break;
			case PhisicalModel_Box1D1M:
					// seteo las puertas
					for (i = 0; i < [doors size]; ++i) {
						door = [doors at: i];
						if ([door getDoorId] == 1)
							[self setDoor: door deleted: TRUE electronicLock: FALSE outerDoor: NULL];
						else
							[self setDoor: door deleted: FALSE electronicLock: FALSE outerDoor: NULL];
					}
		
					// vuelvo a crear los cash de acuerdo al modelo elegido
					cashManId = [cim addCashBox: strCashMan doorId: [doorMan getDoorId] depositType: DepositType_MANUAL];
		
					// seteo los acceptors
					for (i = 0; i < [acceptorSettingsList size]; ++i) {
						acceptorSett = [acceptorSettingsList at: i];
						if ([acceptorSett getAcceptorType] == AcceptorType_VALIDATOR) {
							[self setAcceptor: acceptorSett door: doorVal deleted: TRUE disabled: TRUE];
						} else {
							[self setAcceptor: acceptorSett door: doorMan deleted: FALSE disabled: FALSE];
							[cim addAcceptorByCash: cashManId acceptorId: [acceptorSett getAcceptorId]];
						}
					}
		
				break;

				case PhisicalModel_Flex:
					// seteo las puertas
					for (i = 0; i < [doors size]; ++i) {
						door = [doors at: i];
						if ([door getDoorId] == 1)
							[self setDoor: door deleted: FALSE electronicLock: TRUE outerDoor: NULL];
						else
							[self setDoor: door deleted: FALSE electronicLock: TRUE outerDoor: doorVal];
					}
		
					// vuelvo a crear los cash de acuerdo al modelo elegido
					cashValId = [cim addCashBox: strCashVal doorId: [doorVal getDoorId] depositType: DepositType_AUTO];
					cashManId = [cim addCashBox: strCashMan doorId: [doorMan getDoorId] depositType: DepositType_MANUAL];
		
					// seteo los acceptors
					for (i = 0; i < [acceptorSettingsList size]; ++i) {
						acceptorSett = [acceptorSettingsList at: i];
						if ([acceptorSett getAcceptorType] == AcceptorType_VALIDATOR) {
							[self setAcceptor: acceptorSett door: doorVal deleted: FALSE disabled: FALSE];
							[cim addAcceptorByCash: cashValId acceptorId: [acceptorSett getAcceptorId]];
						} else {
							[self setAcceptor: acceptorSett door: doorMan deleted: FALSE disabled: FALSE];
							[cim addAcceptorByCash: cashManId acceptorId: [acceptorSett getAcceptorId]];
						}
					}
		
				break;
		}
	}

	// seteo validadores *************************
	// los validadores siempre se permiten modificar aunque haya movimientos.
	for (i = 0; i < [acceptorSettingsList size]; ++i) {
		acceptorSett = [acceptorSettingsList at: i];
		if ([acceptorSett getAcceptorType] == AcceptorType_VALIDATOR) {

			model = -1;

			if ( ([acceptorSett getAcceptorId] == 1) && (myVal1Model != -1) )
				model = myVal1Model;

			if ( ([acceptorSett getAcceptorId] == 2) && (myVal2Model != -1) )
				model = myVal2Model;

			switch (model) {
		
				case ValidatorModel_JCM_PUB11_BAG:
						[self setAcceptorModel: acceptorSett brand: BrandType_JCM model: "PUB11|BAG|" parity: 1 stopBits: 0 baudRate: 5 protocol: ProtocolType_ID0003 dataBits: 8];
					break;
				case ValidatorModel_JCM_WBA_Stacker:
						[self setAcceptorModel: acceptorSett brand: BrandType_JCM model: "WBA|SS|" parity: 1 stopBits: 0 baudRate: 5 protocol: ProtocolType_ID0003 dataBits: 8];
					break;
				case ValidatorModel_JCM_BNF_Stacker:
						[self setAcceptorModel: acceptorSett brand: BrandType_JCM model: "BNF|SS|" parity: 1 stopBits: 0 baudRate: 5 protocol: ProtocolType_ID0003 dataBits: 8];
					break;
				case ValidatorModel_JCM_BNF_BAG:
						[self setAcceptorModel: acceptorSett brand: BrandType_JCM model: "BNF|BAG|" parity: 1 stopBits: 0 baudRate: 5 protocol: ProtocolType_ID0003 dataBits: 8];
					break;
				case ValidatorModel_CC_CS_Stacker:
						[self setAcceptorModel: acceptorSett brand: BrandType_CASH_CODE model: "FRONTLOAD MW|V|" parity: 0 stopBits: 0 baudRate: 5 protocol: ProtocolType_CCNET dataBits: 8];
					break;
				case ValidatorModel_CC_CCB_BAG:
						[self setAcceptorModel: acceptorSett brand: BrandType_CASH_CODE model: "CCB|BAG|" parity: 0 stopBits: 0 baudRate: 5 protocol: ProtocolType_CCNET dataBits: 8];
					break;
				case ValidatorModel_MEI_S66_Stacker:
						[self setAcceptorModel: acceptorSett brand: BrandType_MEI model: "S66 BULK|H|" parity: 1 stopBits: 0 baudRate: 5 protocol: ProtocolType_EBDS dataBits: 7];
					break;
			}
		}
	}

	// actualizo el modelo en el box
	box = [cim getBoxById: 1];
	if (box) {

		if (myPhisicalModel == PhisicalModel_Flex)
			[box setBoxModel: "Box_FLEX"];
		else
			[box setBoxModel: [cim getBoxModel]];

		[box applyChanges];
    //************************* logcoment
//		doLog(0,"New BoxModel: %s\n",[box getBoxModel]);

		// audito el cambio de modelo desde la caja.
		[Audit auditEventCurrentUser: Event_CHANGE_BOX_MODEL additional: [box getBoxModel] station: 0 logRemoteSystem: FALSE];
	}

}

@end
