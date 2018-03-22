#include "JManualDepositListForm.h"
#include "UICimUtils.h"
#include "AcceptorSettings.h"
#include "MessageHandler.h"
#include "JSimpleCurrencyForm.h"
#include "DepositDetail.h"
#include "Deposit.h"
#include "UserManager.h"
#include "DepositManager.h"
#include "CimManager.h"
#include "JSimpleTextForm.h"
#include "JSimpleTimerForm.h"
#include "ReportXMLConstructor.h"
#include "PrinterSpooler.h"
#include "JMessageDialog.h"
#include "CimGeneralSettings.h"
#include "Option.h"
#include "CimExcepts.h"
#include "JNeedMoreTimeForm.h"
#include "Audit.h"
#include "Extraction.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)

@implementation  JManualDepositListForm

/**/
- (void) setCimCash: (CIM_CASH) aCimCash 
{ 
	COLLECTION list;
	ACCEPTED_DEPOSIT_VALUE acceptedDepositValue;
	int i;
	ACCEPTOR_SETTINGS acceptorSettings;

	myCimCash = aCimCash; 

	// Si no hay ningun aceptador asociado al cash arrojo una excepcion
	if ([myCimCash getAcceptorSettingsList] == 0)
		THROW(CIM_NO_MAILBOX_IN_CASH_EX);

	acceptorSettings = [[myCimCash getAcceptorSettingsList] at: 0];
	myAcceptedDepositValues = [Collection new];
	list = [acceptorSettings getAcceptedDepositValues];

	// Solo agrego los valores que tienen monedas asociadas
	// de lo contrario podria elegir el valor pero luego no
	// la moneda
	for (i = 0; i < [list size]; ++i) {
		acceptedDepositValue = [list at: i];
		if ([[acceptedDepositValue getAcceptedCurrencies] size] > 0) 
			[myAcceptedDepositValues add: acceptedDepositValue];
	}
	
}

- (void) setCashReference: (CASH_REFERENCE) aCashReference { myCashReference = aCashReference; }
- (id) editInstance: (id) anInstance;

/**/
- (void) onConfigureForm
{
  /**/
	[self setTitle: getResourceStringDef(RESID_MANUAL_DROP_SUMMARY, "Resumen Dep. Manual")];
	[self setAllowNewInstances: FALSE];
	[self setAllowDeleteInstances: TRUE];
	[self setConfirmDeleteInstances: TRUE];
	[self setReturnToFirstItem: TRUE];

}

/**/
- (void) doOpenForm
{
	[[CimManager getInstance] setInManualDropState: TRUE];

	[self setTitle: getResourceStringDef(RESID_MANUAL_DROP_SUMMARY, "Resumen Dep. Manual")];
	[super doOpenForm];
	[self addNewItem];
	if ([[myObjectsList getItemsCollection] size] == 0) {
		[self closeForm];
	}else{
		// audito el inicio del deposito manual
		[Audit auditEventCurrentUser: Event_START_MANUAL_DROP additional: "" station: 0 logRemoteSystem: FALSE];
	}
}

/**/
- (void) onCloseForm
{
	if (myAcceptedDepositValues) [myAcceptedDepositValues free];

	[[CimManager getInstance] setInManualDropState: FALSE];
}

/**/
- (id) onNewInstance
{
	DEPOSIT_DETAIL detail;

	detail = [DepositDetail new];
	if ([self editInstance: detail] == NULL) {
		[detail free];
		detail = NULL;
	}
	return detail;
}

/**/
- (void) verifiedStackerQty: (id) anAcceptorSettings
{
	int stackerQty;
	char buf[100];
	id extraction;
	
	extraction = [[ExtractionManager getInstance] getCurrentExtraction: [anAcceptorSettings getDoor]];
	stackerQty = [extraction getCurrentManualDepositCount];

	if ((![extraction hasEmitStackerFull]) && ([anAcceptorSettings getStackerSize] != 0) && ([anAcceptorSettings getStackerSize] <= stackerQty)) {
		sprintf(buf, "%-20s%s", [anAcceptorSettings getAcceptorName], getResourceStringDef(RESID_STACKER_FULL, "Stacker Lleno.      Finalice deposito!"));
		//doLog(0,"alarm = %s\n", buf);
		[JMessageDialog askOKMessageFrom: self withMessage: buf];
		[extraction setHasEmitStackerFull: TRUE];
		[extraction setHasEmitStackerWarning: TRUE];

		[Audit auditEventCurrentUser: EVENT_STACKER_FULL_BY_SETTING additional: "" station: [anAcceptorSettings getAcceptorId] logRemoteSystem: FALSE];

	} else {
		if ((![extraction hasEmitStackerWarning]) && ([anAcceptorSettings getStackerWarningSize] != 0) && ([anAcceptorSettings getStackerWarningSize] <= stackerQty)){
			sprintf(buf, "%-20s%s", [anAcceptorSettings getAcceptorName], getResourceStringDef(RESID_STACKER_FULL_IS_COMING, "Esta por llegar al stacker lleno"));
		//	doLog(0,"alarm = %s\n", buf);
			[JMessageDialog askOKMessageFrom: self withMessage: buf];
			[extraction setHasEmitStackerWarning: TRUE];

			[Audit auditEventCurrentUser: EVENT_VALIDATOR_CAPACITY_WARNING additional: "" station: [anAcceptorSettings getAcceptorId] logRemoteSystem: FALSE];

		}
	}
}

/**/
- (id) editInstance: (id) anInstance
{
	ACCEPTOR_SETTINGS acceptorSettings;
	ACCEPTED_DEPOSIT_VALUE acceptedDepositValue = NULL;
	ACCEPTED_CURRENCY acceptedCurrency = NULL;
	CURRENCY currency = NULL;
	JFORM form;
	money_t amount = 0;
	int step = 0;
	JFormModalResult modalResult;
	int qty = 1;
	id extraction;
	int stackerQty;

	/** @todo: descablear */
	acceptorSettings = [[myCimCash getAcceptorSettingsList] at: 0];

	// verifico si el buzon esta lleno o por llegar a su capacidad maxima
	[self verifiedStackerQty: acceptorSettings];

	// si llego al stacker full no lo dejo hacer depositos manuales
	extraction = [[ExtractionManager getInstance] getCurrentExtraction: [acceptorSettings getDoor]];
	stackerQty = [extraction getCurrentManualDepositCount];
	if (([acceptorSettings getStackerSize] != 0) && ([acceptorSettings getStackerSize] <= stackerQty)){
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_STACKER_FULL_MANUAL_DROP, "No puede hacer depositos manuales con el Stacker Lleno!")];
		return NULL;
	}

	currency = [anInstance getCurrency];
	qty = [anInstance getQty];
	if (qty == 0) qty = 1;
	amount = [anInstance getAmount];

	if ([anInstance getDepositValueType] != DepositValueType_UNDEFINED) {
		acceptedDepositValue = [acceptorSettings getAcceptedDepositValueByType: [anInstance getDepositValueType]];
	}

	if (currency != NULL && acceptedDepositValue != NULL) {
		acceptedCurrency = [acceptedDepositValue getAcceptedCurrencyByCurrencyId: [currency getCurrencyId]];
	}

	
	while (step >= 0 && step < 3) {

		// Paso 1: Elijo el tipo de valor
		if (step == 0) {
			// selecciono el Value Type si es que hay mas de uno creado
			if ([myAcceptedDepositValues size] > 1) {

				acceptedDepositValue = [UICimUtils selectFromCollection: self
					collection: myAcceptedDepositValues
					title: getResourceStringDef(RESID_VALUE_TYPE, "Tipo Valor:")
					showItemNumber: TRUE
					selectedItem: acceptedDepositValue];

			} else {
				if ([myAcceptedDepositValues size] == 1)
					acceptedDepositValue = [myAcceptedDepositValues at: 0];
			}

			if (acceptedDepositValue) step = 1;
			else return NULL;

		}

		// Paso 2: Elijo la moneda
		if (step == 1) {
			if ([[acceptedDepositValue getAcceptedCurrencies] size] > 1) {
	
					acceptedCurrency = [UICimUtils selectFromCollection: self 
					collection: [acceptedDepositValue getAcceptedCurrencies]
					title: getResourceStringDef(RESID_CURRENCY, "Moneda:")
					showItemNumber: TRUE
					selectedItem: acceptedCurrency];
		
			} else {
				if ([[acceptedDepositValue getAcceptedCurrencies] size] == 1)
					acceptedCurrency = [[acceptedDepositValue getAcceptedCurrencies] at: 0];
			}

			if (acceptedCurrency) step = 2;
			else {
				if ([myAcceptedDepositValues size] > 1)
					step = 0;
				else return NULL;
			}

		}
	
		// Paso 3: Elijo la cantidad
		if (step == 2) {
			if ([[CimGeneralSettings getInstance] getAskQtyInManualDrop]) {
  			form = [JSimpleTextForm createForm: self];
  			[form setNumericMode: TRUE];
  			[form setWidth: 4];
  			[form setLongValue: qty];
  			[form setTitle: getResourceStringDef(RESID_MANUAL_DROP, "Deposito manual")];
  			[form setDescription: getResourceStringDef(RESID_QUANTITY, "Cantidad:")];
  			modalResult = [form showModalForm];
  			qty = [form getLongValue];
  			[form free];
  
  			if (modalResult == JFormModalResult_CANCEL) {
					if ([[acceptedDepositValue getAcceptedCurrencies] size] > 1)
  					step = 1;
					else if ([myAcceptedDepositValues size] > 1)
									step = 0;
							 else return NULL;

  			} else if (qty <= 0) {
  				[JMessageDialog askOKMessageFrom: self 
  						withMessage: getResourceStringDef(RESID_QUANTITY_GREATER_THAN, "La cantidad debe ser mayor a 0.")];
  			} else {
  				step = 3;
  			}
			}else{
				qty = 1;
				step = 3;
			}
		}

		// Paso 3: Elijo el importe
		if (step == 3) {
	
			currency = [acceptedCurrency getCurrency];

			form = [JSimpleCurrencyForm createForm: self];
			[form setTitle: getResourceStringDef(RESID_MANUAL_DROP, "Deposito manual")];
			[form setDescription: getResourceStringDef(RESID_TOTAL_AMOUNT, "Monto Total:")];
			[form setCurrencyCode: [currency getCurrencyCode]];
			[form setMoneyValue: amount];
			modalResult = [form showModalForm];
			amount = [form getMoneyValue];
			[form free];

			if (modalResult == JFormModalResult_CANCEL) {
			  if ([[CimGeneralSettings getInstance] getAskQtyInManualDrop]) {
				  step = 2;
				} else if ([[acceptedDepositValue getAcceptedCurrencies] size] > 1)
								 step = 1;
							 else if ([myAcceptedDepositValues size] > 1)
											step = 0;
							 			else return NULL;
			}
		}

	}
	
	[anInstance setDepositValueType: [acceptedDepositValue getDepositValueType]];
	[anInstance setCurrency: currency];
	[anInstance setQty: qty];
	[anInstance setAmount: amount];
	[anInstance setAcceptorSettings: acceptorSettings];

	return anInstance;
}

/**/
- (void) onSelectInstance: (id) anInstance
{
}

/**/
- (void) onDeleteInstance: (id) anInstance
{

}	

/**/
- (char *) getDeleteInstanceMessage: (char *) aMessage toSave: (id) anInstance
{
	snprintf(aMessage, JCustomForm_MAX_MESSAGE_SIZE, "Eliminar: %s?", [anInstance str]);
	return aMessage;
}

/**/
- (char *) getCaptionX
{
	if (myObjectsList != NULL && [[myObjectsList getItemsCollection] size] > 0) 
		return getResourceStringDef(RESID_DELETE_KEY, "borrar");

	return NULL;
}

/**/
- (char *) getCaption1
{
	return getResourceStringDef(RESID_MORE, "mas");
}

/**/
- (char *) getCaption2
{
	if (myObjectsList == NULL || [[myObjectsList getItemsCollection] size] == 0) return NULL;
	return getResourceStringDef(RESID_ENTER, "entrar");
}

/**/
- (void) onMenuXButtonClick
{
	if ([[myObjectsList getItemsCollection] size] != 0) {
		if ([JMessageDialog askYesNoMessageFrom: self 
					withMessage: getResourceStringDef(RESID_DELETE_MANUAL_DROP_ITEM, "Borrar item deposito manual?")] == JDialogResult_YES) {
			[self removeItem: [myObjectsList getSelectedItem]];
			[self doChangeStatusBarCaptions];
		}
	}
}


/**/
- (void) addDepositDetails: (DEPOSIT) aDeposit
{
	COLLECTION items;
	int i;
	DEPOSIT_DETAIL detail;

	items = [myObjectsList getItemsCollection];  

	// Agrego la lista de items al deposito
	for (i = 0; i < [items size]; ++i) {

		detail = [items at: i];

		[aDeposit addDepositDetail: [detail getAcceptorSettings]
			depositValueType: [detail getDepositValueType]
			currency: [detail getCurrency]
			qty: [detail getQty]
			amount: [detail getAmount]];
		
	}

}

/**/
- (BOOL) doYouNeedMoreTime
{
	OTIMER timer;
	JNEED_MORE_TIME_FORM form;
	JFormModalResult modalResult;

	form = [JNeedMoreTimeForm createForm: NULL];

	timer = [OTimer new];

	[timer initTimer: ONE_SHOT 
			period: [[CimGeneralSettings getInstance] getWarningTime] * 1000 
			object: form 
			callback: "cancelForm"];

	[timer start];

	[form setCloseTimer: timer];
	[form isManualDrop: TRUE]; // le indico que es manual drop para que muestre otro mensaje
	modalResult = [form showModalForm];

	[form free];
	[timer free];

	return ((modalResult == JFormModalResult_YES) || (modalResult == JFormModalResult_CANCEL));
}

/**/
- (void) onMenu2ButtonClick
{
	DEPOSIT deposit;
	char envelopeNumber[30];
	char applyTo[30];
	JFORM form;
	JFormModalResult modalResult;
	USER user = [[UserManager getInstance] getUserLoggedIn];
	scew_tree *tree;

	strcpy(envelopeNumber, "");
	strcpy(applyTo, "");

	if (myIamClosing) {
		//doLog(0,"Me voy porque el formulario se esta cerrando\n");
		return;
	}

	// Si no hay items agregados me voy
	if ([[myObjectsList getItemsCollection] size] == 0) return;

	if ([[CimGeneralSettings getInstance] getAskEnvelopeNumber]) {

		// Solicito el numero de sobre
		if (![UICimUtils askEnvelopeNumber: self
			envelopeNumber: envelopeNumber
			title: getResourceStringDef(RESID_MANUAL_DROP, "Deposito manual")
			description: getResourceStringDef(RESID_ENVELOP_MENOR, "Numero de sobre:")]) return;
	}

	// Solicito el APPLY TO (si corresponde)
	if ([[CimGeneralSettings getInstance] getAskApplyTo]) {

		if (![UICimUtils askApplyTo: self
			applyTo: applyTo
			title: getResourceStringDef(RESID_MANUAL_DROP, "Deposito manual")
			description: getResourceStringDef(RESID_APPLIED_TO, "Aplicar a:")]) return;
	}

	// Genero el comprobante del deposito que va en el sobre
	deposit = [[DepositManager getInstance] getNewDeposit: user cimCash: myCimCash depositType: DepositType_MANUAL];
	[deposit setEnvelopeNumber: envelopeNumber];
	[deposit setApplyTo: applyTo];
	[deposit setCashReference: myCashReference];
	[self addDepositDetails: deposit];

	// Imprimo el comprobante
	tree = [[ReportXMLConstructor getInstance] buildXML: deposit entityType: MANUAL_DEPOSIT_RECEIPT_PRT isReprint: FALSE];
	[[PrinterSpooler getInstance] addPrintingJob: DEPOSIT_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];

	// Libero el deposito anterior (era temporal)	
	[deposit free];

	// Espero hasta que se deposite el sobre
	while (TRUE) {

		form = [JSimpleTimerForm createForm: self];
		[form setTimeout: [[CimGeneralSettings getInstance] getMaxInactivityTimeOnDeposit]];
		[form setTitle: getResourceStringDef(RESID_ADD_VALUES_INTO_ENVELOPE, "Ingrese valores y comprobante en el sobre.")];
		[form setCanCancel: TRUE];
		[form setShowTimer: FALSE];
		modalResult = [form showModalForm];
		[form free];

		if (modalResult == JFormModalResult_YES) break;
		if (modalResult == JFormModalResult_CANCEL) {
			if (![self doYouNeedMoreTime]) continue;
			else {
				// audito la cancelacion del deposito manual
				[Audit auditEventCurrentUser: Event_CANCEL_MANUAL_DROP additional: "" station: 0 logRemoteSystem: FALSE];

				[self closeForm];
				return;
			}

		}

		if ([JMessageDialog askYesNoMessageFrom: self 
					withMessage: getResourceStringDef(RESID_CANCEL_MANUL_DROP_QUESTION, "Esta seguro de cancelar el deposito manual?")] == JDialogResult_YES) {

			// audito la cancelacion del deposito manual
			[Audit auditEventCurrentUser: Event_CANCEL_MANUAL_DROP additional: "" station: 0 logRemoteSystem: FALSE];

			[self closeForm];
			return;
		}

	}

	// Espero hasta que se deposite el sobre
	while (TRUE) {
		form = [JSimpleTimerForm createForm: self];
		[form setTimeout: [[CimGeneralSettings getInstance] getMailboxOpenTime]];
		[form setTitle: getResourceStringDef(RESID_INSERT_ENVELOPE, "Inserte el sobre!")];
		[form setCanCancel: TRUE];
		[form setShowTimer: TRUE];
		modalResult = [form showModalForm];
		[form free];

		if (modalResult == JFormModalResult_YES) break;
		if (modalResult == JFormModalResult_CANCEL) {
			if (![self doYouNeedMoreTime]) continue;
			else {
				// audito la cancelacion del deposito manual
				[Audit auditEventCurrentUser: Event_CANCEL_MANUAL_DROP additional: "" station: 0 logRemoteSystem: FALSE];

				[self closeForm];
				return;
			}

		}

		if ([JMessageDialog askYesNoMessageFrom: self 
					withMessage: getResourceStringDef(RESID_CANCEL_MANUL_DROP_QUESTION, "Esta seguro de cancelar el deposito manual?")] == JDialogResult_YES) {

			// audito la cancelacion del deposito manual
			[Audit auditEventCurrentUser: Event_CANCEL_MANUAL_DROP additional: "" station: 0 logRemoteSystem: FALSE];

			[self closeForm];
			return;
		}


	}

	// Genero el deposito real
	deposit = [[CimManager getInstance] startDeposit: myCimCash depositType: DepositType_MANUAL];
	[deposit setEnvelopeNumber: envelopeNumber];
	[deposit setApplyTo: applyTo];
	[deposit setCashReference: myCashReference];
	[self addDepositDetails: deposit];

	// Finalizo el deposito (se graba e imprime)
	[[CimManager getInstance] endDeposit];

	myModalResult = JFormModalResult_OK;
	
	[self closeForm];
}

#define OPTION_ADD_ITEM 		1
#define OPTION_EDIT_ITEM    2
#define OPTION_CANCEL_DROP	3

/**/
- (void) onMenu1ButtonClick
{
	COLLECTION options = [Collection new];
	OPTION option;
	int keyOption = -1;

	[options add: [Option newOption: OPTION_ADD_ITEM value: getResourceStringDef(RESID_ADD_ITEM, "Agregar Item")]];

	if ([myObjectsList getSelectedItem] != NULL) {
		[options add: [Option newOption: OPTION_EDIT_ITEM value: getResourceStringDef(RESID_EDIT_ITEM, "Editar Item")]];
	}

	[options add: [Option newOption: OPTION_CANCEL_DROP value: getResourceStringDef(RESID_CANCEL_DROP, "Cancelar Deposito")]];

	option = [UICimUtils selectFromCollection: self
		collection: options
		title: ""
		showItemNumber: TRUE];

	if (option != NULL) keyOption = [option getKeyOption];

	[options freeContents];
	[options free];

	if (keyOption == -1) return;

	if (keyOption == OPTION_ADD_ITEM) {
		[self addNewItem];
		[self doChangeStatusBarCaptions];
		return;
	}

	if (keyOption == OPTION_CANCEL_DROP) {
		if ([JMessageDialog askYesNoMessageFrom
: self 
					withMessage: getResourceStringDef(RESID_CANCEL_MANUL_DROP_QUESTION, "Esta seguro de cancelar el deposito manual?")] == JDialogResult_YES) {

			// audito la cancelacion del deposito manual
			[Audit auditEventCurrentUser: Event_CANCEL_MANUAL_DROP additional: "" station: 0 logRemoteSystem: FALSE];

			[self closeForm];
		}
		[self doChangeStatusBarCaptions];
	}	

	if (keyOption == OPTION_EDIT_ITEM) {
		[self editInstance: [myObjectsList getSelectedItem]];
		[self doChangeStatusBarCaptions];
		return;
	}

}

@end

