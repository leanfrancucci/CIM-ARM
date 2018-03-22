#include "JAutomaticDepositForm.h"
#include "CimManager.h"
#include "JNeedMoreTimeForm.h"
#include "MessageHandler.h"
#include "UICimUtils.h"
#include "Option.h"
#include "AmountSettings.h"
#include "JMessageDialog.h"
#include "Audit.h"
#include "JExceptionForm.h"

#define NEED_MORE_TIME_EVENT	9988

#define OPTION_AMOUNT_VIEW			1
#define OPTION_QTY_VIEW					2
#define OPTION_REOPEN           3

#define LOG(args...) //doLog(0,args)
//#define printd(args...)

@implementation  JAutomaticDepositForm

- (void) informStatusChange;
- (void) updateAmounts;

/**/
- (BOOL) isDepositOk
{
	return myIsDepositOK;
}

/**/
- (void) setCimCash: (CIM_CASH) anCimCash
{
	myCimCash = anCimCash;
}

/**/
- (void) setCashReference: (CASH_REFERENCE) aCashReference
{
	myCashReference = aCashReference;
}

/**/
- (void) setUser: (USER) aUser
{
	myUser = aUser;
}

/**/
- (void) setEnvelopeNumber: (char *) anEnvelopeNumber
{
	stringcpy(myEnvelopeNumber, anEnvelopeNumber);
}

/**/
- (void) setApplyTo: (char *) anApplyTo
{
	stringcpy(myApplyTo, anApplyTo);
}

/**/
- (int) getTotalStackerSize: (id) anAcceptorSetting
{
	id cimCash;
	COLLECTION acceptors;
	int i;
	int sSize = 0;

	cimCash = [[[CimManager getInstance] getCim] getCimCashByAcceptorId: [anAcceptorSetting getAcceptorId]];
	acceptors = [cimCash getAcceptorSettingsList];
	for (i=0; i<[acceptors size]; ++i)  {
		sSize+= [[acceptors at: i] getStackerSize];
	}
	
	return sSize;

}

/**/
- (int) getTotalStackerWarningSize: (id) anAcceptorSetting
{
	id cimCash;
	COLLECTION acceptors;
	int i;
	int sWarningSize = 0;

	cimCash = [[[CimManager getInstance] getCim] getCimCashByAcceptorId: [anAcceptorSetting getAcceptorId]];
	acceptors = [cimCash getAcceptorSettingsList];
	
	for (i=0; i<[acceptors size]; ++i) {
		sWarningSize+= [[acceptors at: i] getStackerWarningSize];
	}
	
	return sWarningSize;

}

/**/
- (void) doOpenForm
{
	COLLECTION acceptors;
	int i;
	char buf[21];
	int stackerQty;
	int stackerSize;
	int stackerWarningSize;
	char buff[100];
	JFORM processForm;
	BOOL hasEmitWarning = FALSE;

	[super doOpenForm];

	myModalRes = JFormModalResult_NONE;
	myIsDepositOK = FALSE;
	myIsClosingDeposit = FALSE;
	myIsViewMode = FALSE;
	myTotalDecimals = [[AmountSettings getInstance] getTotalRoundDecimalQty];
	myNeedMoreTimeForm = NULL;
	myDeposit = NULL;
	myCurrentView = AutomaticDepositView_AMOUNT;
	myLabelTitle = [JLabel new];
	[myLabelTitle setCaption: getResourceStringDef(RESID_AMOUNT_VIEW_WAITING, "Vista importe-Esperando")];
	[myLabelTitle setWidth: 20];
	[self addFormComponent: myLabelTitle];
	[self addFormEol];

	myGrid = [JGrid new];
	/** @todo: con el efence me tira un error si esto esta en TRUE */
	[myGrid setOwnObjects: TRUE];
	[myGrid setHeight: 2];
	acceptors = [myCimCash getAcceptorSettingsList];

	// recorro los validadores para mostrar el cartel de deshabilidao cuando corresponda
	for (i = 0; i < [acceptors size]; ++i) {

		// Si es FLEX debe tomar la configuracion de algun lado
		if (strstr([[[[CimManager getInstance] getCim] getBoxById: 1] getBoxModel], "FLEX")) {

			stackerQty = [[[ExtractionManager getInstance] getCurrentExtraction: [[acceptors at: i] getDoor]] getQty: NULL];
			// debo tomar el total del tamano que es la sumatoria de los montos de los stackers de cada aceptador
			stackerSize = [self getTotalStackerSize: [acceptors at: i]];
			stackerWarningSize = [self getTotalStackerWarningSize: [acceptors at: i]];
			printf("stacker size = %d\n", stackerSize);
			printf("stacker warning size = %d\n", stackerWarningSize);
			printf("stacker qty = %d\n", stackerQty);

		} else {

			// si es stacker full no le habilito el validador
			stackerQty = [[[ExtractionManager getInstance] getCurrentExtraction: [[acceptors at: i] getDoor]] getQtyByAcceptor: [acceptors at: i]];

			stackerSize = [[acceptors at: i] getStackerSize];
			stackerWarningSize = [[acceptors at: i] getStackerWarningSize];
		}


		if ((stackerSize != 0) && (stackerSize <= stackerQty)){

			if (strstr([[[[CimManager getInstance] getCim] getBoxById: 1] getBoxModel], "FLEX")) {

				if (!hasEmitWarning) {
					sprintf(buff, "%s", getResourceStringDef(RESID_ACCEPTORS_DISABLED, "Validadores deshabilitados. Stacker Lleno!"));
					[JMessageDialog askOKMessageFrom: self withMessage: buff];
					hasEmitWarning = TRUE;
				}
	
			} else {
				sprintf(buff, "%-20s %s", [[acceptors at: i] getAcceptorName], getResourceStringDef(RESID_STACKER_FULL_VALIDATED_DROP, "Sera deshabilitado. Stacker esta Lleno!"));
				[JMessageDialog askOKMessageFrom: self withMessage: buff];
			}
		}
	}

	for (i = 0; i < [acceptors size]; ++i) {

		// >Valx: ARS      0.00
		// 01234567890123456789
		sprintf(buf, "Val%1d: %-3s      0.00", [[acceptors at: i] getAcceptorId], [[[acceptors at: i] getDefaultCurrency] getCurrencyCode]);
    [myGrid addString: buf];

	}

	[self addFormComponent: myGrid];
	
	myCloseTimer = NULL;

	// Inicia el deposito
	[[CimManager getInstance] addObserver: self];


  processForm = [JExceptionForm showProcessForm2: self msg: getResourceStringDef(RESID_PROCESSING, "Procesando...")];

	myDeposit = [[CimManager getInstance] startDeposit: myUser cimCash: myCimCash depositType: DepositType_AUTO];

	[processForm closeProcessForm];
	[processForm free];

	// audito el inicio del deposito validado
	[Audit auditEvent: [myDeposit getUser] eventId: Event_START_VALIDATED_DROP additional: "" station: 0 logRemoteSystem: FALSE];

	[myDeposit setCashReference: myCashReference];
	[myDeposit setEnvelopeNumber: myEnvelopeNumber];
	[myDeposit setApplyTo: myApplyTo];

	[self informStatusChange];

}

/**/
- (void) closeNeedMoreTimeForm
{
	if (myNeedMoreTimeForm == NULL) return;

	// Cancela el formulario de necesita mas tiempo
	[myNeedMoreTimeForm cancelForm];
}

/**/
- (void) onMenu1ButtonClick
{
	COLLECTION options = [Collection new];
	OPTION option;
	int keyOption = -1;

	myIsViewMode = TRUE;

	[options add: [Option newOption: OPTION_AMOUNT_VIEW value: getResourceStringDef(RESID_AMOUNT_VIEW, "Vista imp.")]];
	[options add: [Option newOption: OPTION_QTY_VIEW value: getResourceStringDef(RESID_QTY_VIEW, "Vista cant")]];

  if ([[[CimManager getInstance] getCim] canReopenCimCash: myCimCash]) {
    [options add: [Option newOption: OPTION_REOPEN value: getResourceStringDef(RESID_RESTART_COIN_COUNT, "Mas monedas")]];
  }

	option = [UICimUtils selectFromCollection: self
		collection: options
		title: ""
		showItemNumber: TRUE];

	if (option != NULL) keyOption = [option getKeyOption];

	[options freeContents];
	[options free];

	myIsViewMode = FALSE;

	if (keyOption == OPTION_AMOUNT_VIEW) {
		[myLabelTitle setCaption: getResourceStringDef(RESID_AMOUNT_VIEW_WAITING, "Vista imp.-Esperando")];
		myCurrentView = AutomaticDepositView_AMOUNT;
	} else if (keyOption == OPTION_QTY_VIEW) {
		[myLabelTitle setCaption: getResourceStringDef(RESID_QTY_VIEW_WAITING, "Vista cant-Esperando")];
		myCurrentView = AutomaticDepositView_QTY;
	} else if (keyOption == OPTION_REOPEN) {
    [[[CimManager getInstance] getCim] reopenCimCash: myCimCash];
  }

	[self updateAmounts];
}

/**/
- (void) onMenu2ButtonClick
{
	if (!myIsClosingDeposit){
		myIsClosingDeposit = TRUE;

		// Cerrando el deposito
		[myLabelTitle setCaption: getResourceStringDef(RESID_CLOSING, "Cerrando...")];

		// Termina el deposito
#ifdef __DEBUG_CIM
		if (myDeposit) {
			[myDeposit debug];
		}
#endif

		// Finalizo el deposito
		[[CimManager getInstance] endDeposit];
	}

}

/**/
- (char *) getCaption1
{	
	return getResourceStringDef(RESID_MORE, "mas");
}

/**/
- (char *) getCaption2
{
	return getResourceStringDef(RESID_ENTER, "entrar");
}

/**/
- (void) onMenuXButtonClick
{
	if (myDeposit == NULL || [myDeposit getQty] == 0) {
		myModalRes = JFormModalResult_CANCEL;

		// audito la cancelacion del deposito validado
		if (myDeposit)
			[Audit auditEvent: [myDeposit getUser] eventId: Event_CANCEL_VALIDATED_DROP additional: "" station: 0 logRemoteSystem: FALSE];
		else
			[Audit auditEventCurrentUser: Event_CANCEL_VALIDATED_DROP additional: "" station: 0 logRemoteSystem: FALSE];

		[self onMenu2ButtonClick];	
	}
}

/**/
- (char *) getCaptionX
{
	if (myDeposit == NULL || [myDeposit getQty] == 0) return getResourceStringDef(RESID_CANCEL_KEY, "cancel");
	return NULL;
}

/**/
- (void) updateAmounts
{
	COLLECTION acceptors;
	char buf[21];
	char moneyStr[30];
	int i;

	if (myDeposit == NULL) return;
	if (myNeedMoreTimeForm != NULL) return;

	acceptors = [myCimCash getAcceptorSettingsList];

	for (i = 0; i < [acceptors size]; ++i) {

		if (myCurrentView == AutomaticDepositView_AMOUNT) {

			formatMoney(moneyStr, "", [myDeposit getAmountByAcceptorSettings: [acceptors at: i]], myTotalDecimals, 9);
			sprintf(buf, "Val%1d: %-3s %9s", [[acceptors at: i] getAcceptorId], [[[acceptors at: i] getDefaultCurrency] getCurrencyCode], moneyStr);

		} else {

			sprintf(buf, "Val%1d: %-3s       %03d", [[acceptors at: i] getAcceptorId], [[[acceptors at: i] getDefaultCurrency] getCurrencyCode],
				[myDeposit getQtyByAcceptorSettings: [acceptors at: i]]);

		}

		[myGrid setString: buf index: i];

	}

	[myGrid paintComponent];

}

/**/
- (void) onBillAccepting: (ABSTRACT_ACCEPTOR) anAcceptor
{
}

/**/
- (void) onAcceptorError: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause
{
}

/**/
- (void) onBillAccepted: (ABSTRACT_ACCEPTOR) anAcceptor currency: (CURRENCY) aCurrency amount: (money_t) anAmount  qty: (int) aQty
{

	[self closeNeedMoreTimeForm];

	if (myDeposit == NULL) return;

	[self updateAmounts];
	[self doChangeStatusBarCaptions];

}

/**/
- (void) onBillRejected: (ABSTRACT_ACCEPTOR) anAcceptor cause: (int) aCause  qty: (int) aQty
{

	[self closeNeedMoreTimeForm];

}

/**/
- (void) onOpenDeposit
{

	[myLabelTitle setCaption: getResourceStringDef(RESID_AMOUNT_VIEW_WAITING, "Vista imp.-Esperando")];

	[self doChangeStatusBarCaptions];
}

/**/
- (void) onCloseDeposit
{
	LOG("JAutomaticDepositForm -> onCloseDeposit\n");

	[self closeNeedMoreTimeForm];

	[myLabelTitle setCaption: getResourceStringDef(RESID_CLOSE, "Cerrado")];

	[[CimManager getInstance] removeObserver: self];

	if (myModalRes != JFormModalResult_CANCEL){
		if (myDeposit == NULL || [myDeposit getQty] == 0)
			myModalRes = JFormModalResult_CANCEL;
		else{
			myModalRes = JFormModalResult_OK;
			myIsDepositOK = TRUE;
		}
	}

	myDeposit = NULL;

	[self closeForm];
}

/**/
- (BOOL) doProcessMessage: (JEvent *) anEvent
{
	JFormModalResult modalResult;

	if (anEvent->evtid == NEED_MORE_TIME_EVENT) {
		if (!myIsClosingDeposit){

				LOG("JAutomaticDepositForm -> doProcessMessage\n");

				// Muestro el formulario de necesita mas tiempo?
				myNeedMoreTimeForm = [JNeedMoreTimeForm createForm: self];
				[myNeedMoreTimeForm setCloseTimer: myCloseTimer];
				modalResult = [myNeedMoreTimeForm showModalForm];
				[myNeedMoreTimeForm free];
				myNeedMoreTimeForm = NULL;

				if (modalResult == JFormModalResult_YES) [[CimManager getInstance] needMoreTime];
				else if (modalResult == JFormModalResult_NO) [self onMenu2ButtonClick];
				 	else if (modalResult == JFormModalResult_CANCEL){
									if (myDeposit == NULL || [myDeposit getQty] == 0)
										myModalRes = JFormModalResult_CANCEL;
									else{
										myModalRes = JFormModalResult_OK;
										myIsDepositOK = TRUE;
									}
								}

				[self updateAmounts];
		}

		return TRUE;
	}

	return [super doProcessMessage: anEvent];
}

/**/
- (void) onInactivityWarning: (OTIMER) aTimer
{
	JEvent		evt;

	if (!myIsViewMode){
		myCloseTimer = aTimer;
		LOG("JAutomaticDepositForm -> onInactivityWarning\n");

		evt.evtid = NEED_MORE_TIME_EVENT;
		[myEventQueue putJEvent: &evt];
	}else{
		[[CimManager getInstance] needMoreTime];
	}
}

/**/
- (void) informCommunicationError: (int) aCause
{
	/*char text[21];
	sprintf(text, "ERROR: %x    ", aCause & 0xFF);
	[myLabelStatus setCaption: text];
	[self informStatusChange];
*/
}

/**/
- (void) informStatusChange
{
/*	char text[31];
	BillValidatorState state;

	if ([myBillValidator isOpen]) {
		strcpy(text, "Abierta / ");
	} else  {
		strcpy(text, "Cerrada / ");
	}

	state = [myBillValidator getBillValidatorState];

	switch (state) {
		case BillValidatorState_ERROR:
			strcat(text, "Error    ");
			break;
		case BillValidatorState_START:
			strcat(text, "Aceptando");
			break;
		case BillValidatorState_STOP:
			strcat(text, "Detenido ");
			break;
	}

	[myLabelTitle setCaption: text];

	[self doChangeStatusBarCaptions];*/
}

@end
