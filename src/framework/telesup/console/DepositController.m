#include <stdio.h>
#include <stdlib.h>
#include "DepositController.h"
#include "log.h"
#include "UICimUtils.h"
#include "MessageHandler.h"
#include "AlarmThread.h"
#include "Audit.h"
#include "CimManager.h"
#include "CimExcepts.h"
#include "CimGeneralSettings.h"
#include "UserManager.h"
#include "AsyncMsgThread.h"
#include "DepositManager.h"
#include "CashReferenceManager.h"
#include "UserManager.h"
#include "ReportXMLConstructor.h"
#include "PrinterSpooler.h"
#include "CimManager.h"


@implementation DepositController

static DEPOSIT_CONTROLLER singleInstance = NULL;


+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}

+ getInstance
{
    return [self new];
}

/**/
- initialize
{
	[super initialize];
    tempManualDeposit = NULL;
/*	myExtractionWorkflow = NULL;
	myInnerExtractionWorkflow = NULL;
    myObserver = NULL;
	myUser1 = NULL;
	myUser2 = NULL;
	myDoorLastState = OpenDoorStateType_UNDEFINED;
	myOuterDoorLastState = OpenDoorStateType_UNDEFINED;
    */
	return self;
    
    
}   

/**/
- (void) setObserver: (id) anObserver
{
    myObserver = anObserver;
}    

/**/
- (void) initManualDrop: (unsigned long) aUserId cashId: (int) aCashId referenceId: (int) aReferenceId applyTo: (char*) anApplyTo envelopeNumber: (char*) anEnvelopeNumber
{

    id cashReference;
    id user;
    id cimCash;
    
    /* VERIFICAR EL STACKER*/
    
    if( tempManualDeposit) [tempManualDeposit free];
    tempManualDeposit = NULL;
    
    user = [[UserManager getInstance] getUser: aUserId];    
    cimCash = [[CimManager getInstance] getCimCashById: aCashId];
	// Genero el comprobante del deposito que va en el sobre
	tempManualDeposit = [[DepositManager getInstance] getNewDeposit: user cimCash: cimCash depositType: DepositType_MANUAL];
	[tempManualDeposit setEnvelopeNumber: anEnvelopeNumber];
	[tempManualDeposit setApplyTo: anApplyTo];
    cashReference = [[CashReferenceManager getInstance] getCashReferenceById: aReferenceId];
	[tempManualDeposit setCashReference: cashReference];
    

}

/**/
- (void) addDropDetail: (int) anAcceptorId depositValueType: (int) aDepositValueType currencyId: (int) aCurrencyId qty: (int) aQty amount: (money_t) anAmount
{
    id acceptorSettings = [[[CimManager getInstance] getCim] getAcceptorSettingsById: anAcceptorId];
    id 	currency = [[CurrencyManager getInstance] getCurrencyById: aCurrencyId];


    [tempManualDeposit addDepositDetail: acceptorSettings
			depositValueType: aDepositValueType
			currency: currency
			qty: aQty
			amount: anAmount];
    
    
}

/**/
- (void) printDropReceipt
{
    scew_tree *tree;
    
 	tree = [[ReportXMLConstructor getInstance] buildXML: tempManualDeposit entityType: MANUAL_DEPOSIT_RECEIPT_PRT isReprint: FALSE];
	[[PrinterSpooler getInstance] addPrintingJob: DEPOSIT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];

}

/**/
- (void) cancelDrop
{
        if (tempManualDeposit) {
            [tempManualDeposit free];
            tempManualDeposit = NULL;
        }   
}
 
/**/ 
- (void) finishDrop
{
    id deposit;
    int i;
    id detail;
    id details;
    
    
	// Genero el deposito real
	deposit = [[CimManager getInstance] startDeposit: [tempManualDeposit getCimCash] depositType: DepositType_MANUAL];
	[deposit setEnvelopeNumber: [tempManualDeposit getEnvelopeNumber]];
	[deposit setApplyTo: [tempManualDeposit getApplyTo]];
	[deposit setCashReference: [tempManualDeposit getCashReference]];
    
    printf("DepositConstroller->finishDrop 1 \n");

	//[self addDepositDetails: deposit];

    details = [tempManualDeposit getDepositDetails];
    
    printf("DepositConstroller->finishDrop 2 \n");
    for (i = 0; i < [details size]; ++i) {

		detail = [details at: i];

        [deposit addDepositDetail: [detail getAcceptorSettings]
			depositValueType: [detail getDepositValueType]
			currency: [detail getCurrency]
			qty: [detail getQty]
			amount: [detail getAmount]];        
    }

       printf("DepositConstroller->finishDrop 3 \n");

	// Finalizo el deposito (se graba e imprime)
	[[CimManager getInstance] endDeposit];
    
        printf("DepositConstroller->finishDrop 4 \n");

    [tempManualDeposit free];       
    
}

@end
