#include "DepositManager.h"
#include "Persistence.h"
#include "ReportXMLConstructor.h"
#include "PrinterSpooler.h"
#include "CimAudits.h"
#include "ExtractionManager.h"
#include "TelesupScheduler.h"
#include "DepositDAO.h"
#include "ZCloseManager.h"
#include "TempDepositDAO.h"
#include "CimManager.h"
#include "TelesupervisionManager.h"
#include "CimGeneralSettings.h"
#include "CimDefs.h"
#include "BillAcceptor.h"
#include "MessageHandler.h"
#include "CommercialStateMgr.h"
#include "CurrencyManager.h"


#include "FTPSupervision.h"

//#define LOG(args...) doLog(0,args)

@implementation DepositManager

static DEPOSIT_MANAGER singleInstance = NULL; 

- (void) recoverDepositForCash: (CIM_CASH) aCimCash lastDeposit: (DEPOSIT) aLastDeposit;

/**/
- (void) recoverDeposits;

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}
 
/**/
- initialize
{
    printf("initialize 1\n");
	myLastDepositNumber = [[[Persistence getInstance] getDepositDAO] getLastDepositNumber];
    printf("initialize 2\n");
	if ([[CimGeneralSettings getInstance] getNextDepositNumber] > myLastDepositNumber)
		myLastDepositNumber = [[CimGeneralSettings getInstance] getNextDepositNumber] - 1;
    printf("initialize 3\n");
	[self recoverDeposits];
    printf("initialize 4\n");
	return self;
}


/**/
+ getInstance
{
  return [self new];
}

/**/
- (DEPOSIT) getNewDeposit: (USER) aUser 
		cimCash: (CIM_CASH) aCimCash
		depositType: (DepositType) aDepositType
{
	DEPOSIT deposit;

	deposit = [Deposit new];

	[deposit setDepositType: aDepositType];
	[deposit setUser: aUser];
	[deposit setDoor: [aCimCash getDoor]];
	[deposit setCimCash: aCimCash];
	[deposit setOpenTime: [SystemTime getLocalTime]];

	return deposit;

}

/**/
- (void) endDeposit: (DEPOSIT) aDeposit
{
	scew_tree *tree;
	char additional[50];
	id telesup;
	unsigned long auditNumber = 0;
  datetime_t auditDateTime = 0;	
  DepositReportParam depositParam;
  
  printf("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n");
  printf("DEPOSIT MANAGER -------------------------------------------END DEPOSIT\n");
  printf("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n");

	// Solo grabo depositos que tengan algun valor
	if (aDeposit != NULL) {
	 if ([aDeposit getQty] > 0) {

		// Controlo si me configuraron un proximo numero de deposito
		if ([[CimGeneralSettings getInstance] getNextDepositNumber] > myLastDepositNumber)
			myLastDepositNumber = [[CimGeneralSettings getInstance] getNextDepositNumber] - 1;

		[aDeposit setNumber: myLastDepositNumber + 1];

		// Configuro la fecha/hora del deposito
		[aDeposit setCloseTime: [SystemTime getLocalTime]];

		// Audito el evento
		auditDateTime = [SystemTime getLocalTime];
		sprintf(additional, "%s %ld", getResourceStringDef(RESID_DROP_DESC, "Deposito"), [aDeposit getNumber]);

	  if ([aDeposit getDepositType] == DepositType_MANUAL)
		  auditNumber = [Audit auditEventCurrentUserWithDate: AUDIT_CIM_DEPOSIT additional: additional station: [[aDeposit getCimCash] getCimCashId] datetime: auditDateTime logRemoteSystem: FALSE];
		else
		  auditNumber = [Audit auditEventWithDate: [aDeposit getUser] eventId: Event_AUTO_DROP additional: additional station: [[aDeposit getCimCash] getCimCashId] datetime: auditDateTime logRemoteSystem: FALSE];    
	  depositParam.auditNumber = auditNumber;
	  depositParam.auditDateTime = auditDateTime;

		// Grabo el deposito
		[[[Persistence getInstance] getDepositDAO] store: aDeposit];

		// Elimino el deposito temporal
		[[[Persistence getInstance] getTempDepositDAO] clearDeposit: aDeposit];

		// Imprimo el deposito
		tree = [[ReportXMLConstructor getInstance] buildXML: aDeposit entityType: DEPOSIT_PRT isReprint: FALSE varEntity: &depositParam];
		[[PrinterSpooler getInstance] addPrintingJob: DEPOSIT_PRT 
			copiesQty: [[CimGeneralSettings getInstance] getDepositCopiesQty]
			ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];

		// Actualizo los valores actuales de caja (extraccion)
		[[ExtractionManager getInstance] processDeposit: aDeposit];

		if ([[CimGeneralSettings getInstance] getUseEndDay]) 
			[[ZCloseManager getInstance] processDeposit: aDeposit];

		// Obtengo el ultimo numero de deposito
		myLastDepositNumber = [aDeposit getNumber];

		// libero el objeto
		[aDeposit free];

		/* supervisa si:
		1.existe la supervision
		2.puede ejecutar el modulo
		3.el modulo tiene configurado online
		4.esta configurada online el envio de depositos en la telesup
		*/

        printf("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n");
        printf("Agarra la supervision PIMS\n");
        
		telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];

        if( telesup ) printf("HAY supervision PIMS\n");
        
		if ( telesup && 
					[telesup getInformDepositsByTransaction] /*&&
					[[CommercialStateMgr getInstance] canExecuteModule: ModuleCode_SEND_DROPS] &&
					[[[CommercialStateMgr getInstance] getModuleByCode: ModuleCode_SEND_DROPS] getOnline] */) {
            if( telesup ) printf("SUPERVISA PIMS\n");

            //************************* logcoment
			//doLog(0,"Supervisa el deposito\n");
	
			[[TelesupScheduler getInstance] setCommunicationIntention: CommunicationIntention_INFORM_DEPOSITS];
			[[TelesupScheduler getInstance] startTelesupInBackground];
		}

		telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: HOYTS_BRIDGE_TSUP_ID];

		if ( telesup && 
					[telesup getInformDepositsByTransaction]) {

			    //************************* logcoment
            //doLog(0,"Supervisa el deposito a Hoyts\n");                
	
			[[TelesupScheduler getInstance] setCommunicationIntention: CommunicationIntention_INFORM_DEPOSITS];
			[[TelesupScheduler getInstance] startTelesupInBackground: HOYTS_BRIDGE_TSUP_ID];
		}

		telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: BRIDGE_TSUP_ID];

		if ( telesup && 
					[telesup getInformDepositsByTransaction]) {

			    //************************* logcoment
                //doLog(0,"Supervisa el deposito a Bridge\n");                
	
			[[TelesupScheduler getInstance] setCommunicationIntention: CommunicationIntention_INFORM_DEPOSITS];
			[[TelesupScheduler getInstance] startTelesupInBackground: BRIDGE_TSUP_ID];
		}

		telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: FTP_SERVER_TSUP_ID];

		if (telesup && [telesup getInformDepositsByTransaction]) {
			    //************************* logcoment
                //doLog(0,"Supervisa el deposito por ftp\n");
			[[TelesupScheduler getInstance] setCommunicationIntention: CommunicationIntention_INFORM_DEPOSITS];
			[[TelesupScheduler getInstance] startTelesupInBackground: FTP_SERVER_TSUP_ID];
		}

	 }
	}

}

/**/
- (void) recoverDeposits
{
	CIM_CASH cimCash = NULL;
	int i;
	COLLECTION cimCashs;
	DEPOSIT lastDeposit;

	cimCashs = [[[CimManager getInstance] getCim] getCimCashs];

    printf("1\n");
	// Recupero el ultimo deposito guardado
	lastDeposit = [[[Persistence getInstance] getDepositDAO] loadLast];
    printf("2\n");
	// En primer lugar debo recuperar el deposito temporal del ultimo cash guardado
	if (lastDeposit) cimCash = [lastDeposit getCimCash];
    printf("3\n");
	if (cimCash) {
		[self recoverDepositForCash: cimCash lastDeposit: lastDeposit];
	}
    printf("4\n");
	// Recupero todos los demas cashs
	for (i = 0; i < [cimCashs size]; ++i) {

		if ([cimCashs at: i] != cimCash) {
			[self recoverDepositForCash: [cimCashs at: i] lastDeposit: lastDeposit];
		}
	}
    printf("5\n");
	if (lastDeposit) [lastDeposit free];
}

/**/
- (void) recoverDepositForCash: (CIM_CASH) aCimCash lastDeposit: (DEPOSIT) aLastDeposit
{
	scew_tree *tree;
	DEPOSIT tempDeposit, deposit, dep;
	COLLECTION tempDepositDetails, lastDepositDetails;
	int i;
	COLLECTION acceptorSettingsList;
	BILL_ACCEPTOR billAcceptor;
	BillAcceptorStatus initStatus;
	int lastStacked = 0;
	long long billAmountTmp;
	int currencyIdTmp;
	char moneyStr[50];

	tempDeposit = [[[Persistence getInstance] getTempDepositDAO] loadLastByCimCash: aCimCash];
	if (tempDeposit == NULL) {
	
			    //************************* logcoment
		//doLog(0,"DepositManager.recoverDeposits()-> Analizando cash %d: Se debe analizar si quedo un billete y no se llego a crear el deposito\n", [aCimCash getCimCashId]);

		acceptorSettingsList = [aCimCash getAcceptorSettingsList];

			    //************************* logcoment
		//doLog(0,"acceptorSettingsList size %d \n", [acceptorSettingsList size]);

		for (i = 0; i < [acceptorSettingsList size]; ++i) {

						    //************************* logcoment
                //doLog(0,"acceptorSettingsType %d \n", [[acceptorSettingsList at: i] getAcceptorType]);

			if ( [[acceptorSettingsList at: i] getAcceptorType] == AcceptorType_VALIDATOR) {
				billAcceptor = [[[CimManager getInstance] getCim] getAcceptorById: [[acceptorSettingsList at: i] getAcceptorId]];


				if (billAcceptor == NULL) {
					continue;
				}


				if ([[acceptorSettingsList at: i] isDisabled]) {
					initStatus = BillAcceptorStatus_POWER_UP;
				}
				else {
			      	initStatus = [billAcceptor waitForInitStatus];
				}

			  lastStacked = [SafeBoxHAL getBillAcceptorLastStacked: [[billAcceptor getAcceptorSettings] getAcceptorHardwareId] billAmount: &billAmountTmp currencyId: &currencyIdTmp];

			  //doLog(0,"lastStacked %d billamount %d \n", lastStacked, billAmountTmp);
			    //************************* logcoment
				
				if (lastStacked > 0 && billAmountTmp > 0)  {

			    //************************* logcoment
//					doLog(0,"Hay un billete en el validador y es el primero, y no llego a crear un deposito y se corto la energia\n");
					formatMoney(moneyStr, [[[CurrencyManager getInstance] getCurrencyById: currencyIdTmp] getCurrencyCode], billAmountTmp, 2, 40);
					[Audit auditEventCurrentUser: Event_BILL_STACKED_WITHOUT_DROP additional: moneyStr
					station: [[acceptorSettingsList at: i] getAcceptorId]
					logRemoteSystem: FALSE];

				}
			}

		}

		return;
	}

			    //************************* logcoment
	//doLog(0,"DepositManager.recoverDeposits()-> Analizando cash %d: se recupero un deposito\n");

#ifdef __DEBUG_CIM
	[tempDeposit debug];
#endif

	if ([[tempDeposit getCimCash] getDepositType] == DepositType_AUTO) {

		acceptorSettingsList = [[tempDeposit getCimCash] getAcceptorSettingsList];

		for (i = 0; i < [acceptorSettingsList size]; ++i) {

			billAcceptor = [[[CimManager getInstance] getCim] getAcceptorById: [[acceptorSettingsList at: i] getAcceptorId]];
			    //************************* logcoment
			/*doLog(0,"Esperando estado inicial del validador %d...", [[acceptorSettingsList at: i] getAcceptorId]);
			doLog(0,"IsDeleted = %d\n", [[acceptorSettingsList at: i] isDeleted]);
			doLog(0,"IsDisabled = %d\n", [[acceptorSettingsList at: i] isDisabled]);
*/
			if (billAcceptor == NULL) continue;

			// Si esta inhabilitado el validador entonces fuerzo un estado POWER_UP falso
			if ([[acceptorSettingsList at: i] isDisabled]) 
				initStatus = BillAcceptorStatus_POWER_UP;
			else
		      initStatus = [billAcceptor waitForInitStatus];

			if ( initStatus == BillAcceptorStatus_COMMUNICATION_ERROR ) {
				[Audit auditEventCurrentUser: Event_COMM_ERROR_WITH_OPEN_DEPOSIT additional: ""
						station: [[acceptorSettingsList at: i] getAcceptorId]
						logRemoteSystem: FALSE];
			}

			//*********************logcoment
            //doLog(0,"Estado Inicial = %d\n", initStatus);

			//if (initStatus == BillAcceptorStatus_POWER_UP_BILL_STACKER) {

			  lastStacked = [SafeBoxHAL getBillAcceptorLastStacked: [[billAcceptor getAcceptorSettings] getAcceptorHardwareId] billAmount: &billAmountTmp currencyId: &currencyIdTmp];

			    //************************* logcoment
			  //doLog(0,"lastStacked %d billamount %d \n", lastStacked, billAmountTmp);
				if (lastStacked > 0 && billAmountTmp > 0)  {

					if ([tempDeposit getQtyByAcceptorSettings: [billAcceptor getAcceptorSettings]] < lastStacked) {
				
			    //************************* logcoment
//						doLog(0,"PASO POR ACA tempDeposit addDepositDetail= \n");
						[tempDeposit addDepositDetail: [acceptorSettingsList at: i] 
							depositValueType: DepositValueType_VALIDATED_CASH
							currency: [[CurrencyManager getInstance] getCurrencyById: currencyIdTmp]
							qty: 1
							amount: billAmountTmp];

						formatMoney(moneyStr, [[[CurrencyManager getInstance] getCurrencyById: currencyIdTmp] getCurrencyCode], billAmountTmp, 2, 40);
						[Audit auditEventCurrentUser: Event_BILL_ADDED_AFTER_RESET additional: moneyStr
						station: [[acceptorSettingsList at: i] getAcceptorId]
						logRemoteSystem: FALSE];

                //*********************logcoment
						//doLog(0,"y salio nomas PASO POR ACA tempDeposit addDepositDetail= \n");
					}
				}

			//}
	
		}

	}
	
	// Si difiere la fecha/hora del ultimo deposito y el cash, quiere decir que no pude
	// ni siquiera comenzar a grabar el deposito temporal y tengo que guardarlo ahora

	if (aLastDeposit == NULL || [tempDeposit getCimCash] != aCimCash || 
			[tempDeposit getOpenTime] != [aLastDeposit getOpenTime]) {

			    //************************* logcoment
	//doLog(0,"DepositManager.recoverDeposits() -> el deposito no existia.\n");

		deposit = tempDeposit;
		
		// Audito el evento
		[Audit auditEventCurrentUser: AUDIT_CIM_RECOVER_DEPOSIT additional: "" station: [[deposit getDoor] getDoorId] logRemoteSystem: FALSE];
		[self endDeposit: deposit];

	} else {

			    //************************* logcoment
//		doLog(0,"DepositManager.recoverDeposits() -> el deposito ya existia.\n");

#ifdef __DEBUG_CIM
		[aLastDeposit debug];
#endif

		// Si el numero de deposito es el mismo, tengo que guardar unicamente las diferencias
		// entre los dos depositos
		tempDepositDetails = [tempDeposit getDepositDetails];
		lastDepositDetails = [aLastDeposit getDepositDetails];

		if ([tempDepositDetails size] < [lastDepositDetails size]) {

			    //************************* logcoment
//			doLog(0,"Error: nunca deberia ocurrir que el deposito guardado tenga mas detalles que el temporal\n");
			deposit = aLastDeposit;

		} else {

			// traigo el ultimo deposito insertado para obtener el numero que se le asigno
			dep = [[[Persistence getInstance] getDepositDAO] loadLast];
			if (dep) {
				[tempDeposit setNumber: [dep getNumber]];
				[dep free];
			}

			deposit = tempDeposit;

			    //************************* logcoment
//			doLog(0,"DepositManager.recoverDeposits() -> cantidad de detalle anterior = %d.\n", [lastDepositDetails size]);
//			doLog(0,"DepositManager.recoverDeposits() -> cantidad de detalle temporal = %d.\n", [tempDepositDetails size]);

			for (i = [lastDepositDetails size]; i < [tempDepositDetails size]; ++i) {
			    //************************* logcoment

                //				doLog(0,"DepositManager.recoverDeposits() -> Grabando detalle.\n");
				[[[Persistence getInstance] getDepositDAO] saveDepositDetail: tempDeposit depositDetail: [tempDepositDetails at: i]];

				// se agregan los detalles aun no agregados en la memoria de la extraccion
				[[ExtractionManager getInstance] processTempDepositDetail: tempDeposit depositDetail: [tempDepositDetails at: i]];

				// // se agregan los detalles aun no agregados en la memoria del cierre Z si esta habilitado el parametro
				if ([[CimGeneralSettings getInstance] getUseEndDay]) 
					[[ZCloseManager getInstance] processTempDepositDetail: tempDeposit depositDetail: [tempDepositDetails at: i]];
				}

			// Vuelvo a cargar el ultimo deposito para que tenga los datos de la fecha correctos
			deposit = [[[Persistence getInstance] getDepositDAO] loadLast];

		}

		// Elimino el deposito temporal
		[[[Persistence getInstance] getTempDepositDAO] clearDeposit: deposit];

		// Imprimo el deposito
		tree = [[ReportXMLConstructor getInstance] buildXML: deposit entityType: DEPOSIT_PRT isReprint: FALSE];
		[[PrinterSpooler getInstance] addPrintingJob: DEPOSIT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];

		if (deposit) [deposit free];
		if (tempDeposit) [tempDeposit free];

	}

}

/**/
- (unsigned long) getLastDepositNumber
{
	return myLastDepositNumber;
}

@end
