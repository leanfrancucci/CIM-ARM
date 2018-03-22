#include "JCimGeneralSettingsEditForm.h"
#include "CimGeneralSettings.h"
#include "MessageHandler.h"
#include "JMessageDialog.h"
#include "JInfoViewerForm.h"
#include "CtSystem.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JCimGeneralSettingsEditForm


/**/
- (void) onCreateForm
{
	char aux[41];
	[super onCreateForm];
	printd("JCimGeneralSettingsEditForm:onCreateForm\n");

	// Cantidad de copiar deposito
	[self addLabelFromResource: RESID_DEPOSIT_COPIES_QTY default: "Drop Recepit Copies:"];
	myTextDepositCopiesQty = [JText new];
  [myTextDepositCopiesQty setWidth: 1];
	[myTextDepositCopiesQty setNumericMode: TRUE];
	[self addFormComponent: myTextDepositCopiesQty];

	// Cantidad de copiar Reporte Parcial
  [self addFormNewPage];
	[self addLabelFromResource: RESID_X_COPIES_QTY default: "Partial Report Copies:"];
	myTextXCopiesQty = [JText new];
  [myTextXCopiesQty setWidth: 1];
	[myTextXCopiesQty setNumericMode: TRUE];
	[self addFormComponent: myTextXCopiesQty];

	// Cantidad de copiar End Of Day
	[self addFormNewPage];
	[self addLabelFromResource: RESID_Z_COPIES_QTY default: "End Of Day Copies:"];
	myTextZCopiesQty = [JText new];
  [myTextZCopiesQty setWidth: 1];
	[myTextZCopiesQty setNumericMode: TRUE];
	[self addFormComponent: myTextZCopiesQty];  

	// Cantidad de copiar Extraction
	[self addFormNewPage];
	[self addLabelFromResource: RESID_EXTRACTION_COPIES_QTY default: "Deposit Copies:"];
	myTextExtractionCopiesQty = [JText new];
  [myTextExtractionCopiesQty setWidth: 1];
	[myTextExtractionCopiesQty setNumericMode: TRUE];
	[self addFormComponent: myTextExtractionCopiesQty];  

	// Print Logo
	[self addFormNewPage];
	[self addLabelFromResource: RESID_PRINT_LOGO default: "Print Logo:"];
	myComboPrintLogo = [self createNoYesCombo];

	// Use Cash References
	[self addFormNewPage];
	[self addLabelFromResource: RESID_USE_CASH_REFERENCE default: "Use Cash References:"];
	myComboUseCashReference = [self createNoYesCombo];

	// Ask Envelope Number
	[self addFormNewPage];
	[self addLabelFromResource: RESID_ASK_ENVELOPE_NUMBER default: "Ask Envelope Number:"];
	myComboAskEnvelopeNumber = [self createNoYesCombo];

	// Ask Qty in Manual Drops
	[self addFormNewPage];
	[self addLabelFromResource: RESID_ASK_QTY_IN_MANUAL_DROPS default: "Ask Qty in Manual Drops:"];
	myComboAskQtyInManualDrop = [self createNoYesCombo];

	// Combo Ask Apply To
	[self addFormNewPage];
	[self addLabelFromResource: RESID_ASK_APPLY_TO default: "Ask Apply To:"];
	myComboAskApplyTo = [self createNoYesCombo];

	// Autoprint
	[self addFormNewPage];
	[self addLabelFromResource: RESID_AUTOPRINT default: "Auto Print End of Day:"];
	myComboAutoPrint = [self createNoYesCombo];

	// End Of Day
	[self addFormNewPage];
	[self addLabelFromResource: RESID_END_DAY default: "End Of Day:"];
	myTimeEndDay = [JTime new];
	[myTimeEndDay setSystemTimeMode: FALSE];
 	[myTimeEndDay setShowConfig: TRUE showMinutes: TRUE showSeconds: FALSE];
	[myTimeEndDay setOperationMode: TimeOperationMode_HOUR_MIN_SECOND];
	[self addFormComponent: myTimeEndDay];

	// Combo Print Operator Report
	[self addFormNewPage];
	[self addLabelFromResource: RESID_PRINT_OPERATOR_REPORT default: "Print Operator Report:"];
	myComboPrintOperatorReport = [JCombo new];
	[myComboPrintOperatorReport addString: getResourceStringDef(RESID_NEVER, "Never")];
	[myComboPrintOperatorReport addString: getResourceStringDef(RESID_ALWAYS, "Always")];
	[myComboPrintOperatorReport addString: getResourceStringDef(RESID_ASK, "Ask")];
	[self addFormComponent: myComboPrintOperatorReport];

	// Pos ID
	[self addFormNewPage];
	[self addLabelFromResource: RESID_POS_ID default: "Pos ID:"];
	myTextPOSId = [JText new];
	[myTextPOSId setWidth: 17];
  [myTextPOSId setMaxLen: 17];
	[self addFormComponent: myTextPOSId];  

	// Envelope Operation Mode
	[self addFormNewPage];
	[self addLabelFromResource: RESID_CIM_GeneralSettings_KEY_PAD_OP_MODE_ENVELOPE_ID default: "Modo Op Env Number:"];
	myComboEnvelopeIdOpMode = [JCombo new];
	[myComboEnvelopeIdOpMode addString: getResourceStringDef(RESID_CIM_GeneralSettings_KEY_PAD_OP_MODE_Numeric, "Numerico")];
	[myComboEnvelopeIdOpMode addString: getResourceStringDef(RESID_CIM_GeneralSettings_KEY_PAD_OP_MODE_Alphanumeric, "Alfanumerico")];
	[self addFormComponent: myComboEnvelopeIdOpMode];

	// ApplyTo Operation Mode
	[self addFormNewPage];
	[self addLabelFromResource: RESID_CIM_GeneralSettings_KEY_PAD_OP_MODE_APPLY_TO default: "Modo Op Apply To:"];
	myComboApplyToOpMode = [JCombo new];
	[myComboApplyToOpMode addString: getResourceStringDef(RESID_CIM_GeneralSettings_KEY_PAD_OP_MODE_Numeric, "Numerico")];
	[myComboApplyToOpMode addString: getResourceStringDef(RESID_CIM_GeneralSettings_KEY_PAD_OP_MODE_Alphanumeric, "Alfanumerico")];
	[self addFormComponent: myComboApplyToOpMode];

	// Login Operation Mode
	[self addFormNewPage];
	[self addLabelFromResource: RESID_CIM_GeneralSettings_KEY_PAD_OP_MODE_LOGIN default: "Modo Op Login:"];
	myComboLoginOpMode = [JCombo new];
	[myComboLoginOpMode addString: getResourceStringDef(RESID_CIM_GeneralSettings_KEY_PAD_OP_MODE_Numeric, "Numerico")];
	[myComboLoginOpMode addString: getResourceStringDef(RESID_CIM_GeneralSettings_KEY_PAD_OP_MODE_Alphanumeric, "Alfanumerico")];
	[self addFormComponent: myComboLoginOpMode];

	// Combo Use BarCode Reader
	[self addFormNewPage];
	[self addLabelFromResource: RESID_USE_BARCODE_READER default: "Usar Lector Cod Bar:"];
	myComboUseBarCodeReader = [self createNoYesCombo];

	// Combo BarCode reader COM port
	[self addFormNewPage];
	sprintf(aux, "%s:", getResourceStringDef(RESID_CIM_GeneralSettings_BARCODE_READER_COM_PORT, "COM lector cod barr"));
	[self addLabel: aux];
	myComboBarCodeReaderComPort = [JCombo new];
	[myComboBarCodeReaderComPort addString: "1"];
	[myComboBarCodeReaderComPort addString: "2"];
	[self addFormComponent: myComboBarCodeReaderComPort];	

	// Combo Remove Bag Verification
	[self addFormNewPage];
	[self addLabelFromResource: RESID_REMOVE_BAG_VERIFICATION default: "Verifica Bolsa Extr:"];
	myComboRemoveBagVerification = [self createNoYesCombo];

	// Combo Bag Tracking
	[self addFormNewPage];
	[self addLabelFromResource: RESID_BAG_TRACKING default: "Seguimiento Bolsas:"];
	myComboBagTracking = [self createNoYesCombo];

	// Combo Remove Cash Outer Door
	[self addFormNewPage];
	[self addLabelFromResource: RESID_REMOVE_CASH_OUTER_DOOR default: "Remover Cash p. ext:"];
	myComboRemoveCashOuterDoor = [self createNoYesCombo];

	// Combo Use End Day
	[self addFormNewPage];
	[self addLabelFromResource: RESID_USE_END_DAY default: "Utiliza End Day:"];
	myComboUseEndDay = [self createNoYesCombo];

	// Combo Ask Bag Code
	[self addFormNewPage];
	[self addLabelFromResource: RESID_ASK_BAG_CODE default: "Ingresa Cod. Bolsa:"];
	myComboAskBagCode = [self createNoYesCombo];

	// Acceptors Code Type
	[self addFormNewPage];
	[self addLabelFromResource: RESID_ACCEPTORS_CODE_TYPE default: "Tipo Cod. Aceptadores:"];
	myComboAcceptorsCodeType = [JCombo new];
	[myComboAcceptorsCodeType addString: getResourceStringDef(RESID_ACCEPTORS_CODE_TYPE_Numeric, "Numerico")];
	[myComboAcceptorsCodeType addString: getResourceStringDef(RESID_ACCEPTORS_CODE_TYPE_Alphanumeric, "Alfanumerico")];
	[self addFormComponent: myComboAcceptorsCodeType];

	// Combo Ask Bag Code
	[self addFormNewPage];
	[self addLabelFromResource: RESID_CONFIRM_CODE default: "Confirma Cod. Aceptador:"];
	myComboConfirmCode = [self createNoYesCombo];

 	[self setConfirmAcceptOperation: TRUE];
	myHasChangedUseEndDay = FALSE;
}

/**/
- (void) onCancelForm: (id) anInstance
{
	printd("JCimGeneralSettingsEditForm:onAcceptForm\n");

	assert(anInstance != NULL);

	[anInstance restore];
}

/**/
- (void) onModelToView: (id) anInstance
{
	printd("JCimGeneralSettingsEditForm:onModelToView\n");

	assert(anInstance != NULL);

	[myTextDepositCopiesQty setLongValue: [anInstance getDepositCopiesQty]];
	[myTextXCopiesQty setLongValue: [anInstance getXCopiesQty]];
	[myTextZCopiesQty setLongValue: [anInstance getZCopiesQty]];
	[myTextExtractionCopiesQty setLongValue: [anInstance getExtractionCopiesQty]];
	[myComboAutoPrint setSelectedIndex: [anInstance getAutoPrint]];
	[myComboPrintLogo setSelectedIndex: [anInstance getPrintLogo]];
	[myComboAskEnvelopeNumber setSelectedIndex: [anInstance getAskEnvelopeNumber]];
	[myComboUseCashReference setSelectedIndex: [anInstance getUseCashReference]];
	[myComboAskQtyInManualDrop setSelectedIndex: [anInstance getAskQtyInManualDrop]];
	[myComboAskApplyTo setSelectedIndex: [anInstance getAskApplyTo]];
	[myComboPrintOperatorReport setSelectedIndex: [anInstance getPrintOperatorReport] - 1];
	[myTimeEndDay setTimeValue: [anInstance getEndDay] / 60 minutes: [anInstance getEndDay] % 60 seconds: 0];
	[myTextPOSId setText: [anInstance getPOSId]];
	[myComboEnvelopeIdOpMode setSelectedIndex: [anInstance getEnvelopeIdOpMode] - 1];
	[myComboApplyToOpMode setSelectedIndex: [anInstance getApplyToOpMode] - 1];
	[myComboLoginOpMode setSelectedIndex: [anInstance getLoginOpMode] - 1];
	[myComboUseBarCodeReader setSelectedIndex: [anInstance getUseBarCodeReader]];
	[myComboRemoveBagVerification setSelectedIndex: [anInstance getRemoveBagVerification]];
	[myComboBagTracking setSelectedIndex: [anInstance getBagTracking]];
	[myComboBarCodeReaderComPort setSelectedIndex: [anInstance getBarCodeReaderComPort] - 1];
	[myComboRemoveCashOuterDoor setSelectedIndex: [anInstance removeCashOuterDoor]];

	// almaceno los valores antes para saber si al grabar se modificaron
	myLastUseBarCodeReader = [anInstance getUseBarCodeReader];
	myLastBarCodeReaderComPort = [anInstance getBarCodeReaderComPort];

	[myComboUseEndDay setSelectedIndex: [anInstance getUseEndDay]];
	[myComboAskBagCode setSelectedIndex: [anInstance getAskBagCode]];
	[myComboAcceptorsCodeType setSelectedIndex: [anInstance getAcceptorsCodeType] - 1];
	[myComboConfirmCode setSelectedIndex: [anInstance getConfirmCode]];

}

/**/
- (void) onViewToModel: (id) anInstance
{
	printd("JCimGeneralSettingsEditForm:onViewToModel\n");

	assert(anInstance != NULL);

	[anInstance setDepositCopiesQty: [myTextDepositCopiesQty getLongValue]];
  [anInstance setXCopiesQty: [myTextXCopiesQty getLongValue]];
	[anInstance setZCopiesQty: [myTextZCopiesQty getLongValue]];
	[anInstance setExtractionCopiesQty: [myTextExtractionCopiesQty getLongValue]];
  [anInstance setAutoPrint: [myComboAutoPrint getSelectedIndex]];
	[anInstance setPrintLogo: [myComboPrintLogo getSelectedIndex]];
	[anInstance setAskEnvelopeNumber: [myComboAskEnvelopeNumber getSelectedIndex]];
	[anInstance setUseCashReference: [myComboUseCashReference getSelectedIndex]];
	[anInstance setAskQtyInManualDrop: [myComboAskQtyInManualDrop getSelectedIndex]];
	[anInstance setAskApplyTo: [myComboAskApplyTo getSelectedIndex]];
	[anInstance setPrintOperatorReport: [myComboPrintOperatorReport getSelectedIndex] + 1];
	[anInstance setEndDay: [myTimeEndDay getHours] * 60 + [myTimeEndDay getMinutes]];
	[anInstance setPOSId: [myTextPOSId getText]];
	[anInstance setEnvelopeIdOpMode: [myComboEnvelopeIdOpMode getSelectedIndex] + 1];
	[anInstance setApplyToOpMode: [myComboApplyToOpMode getSelectedIndex] + 1];
	[anInstance setLoginOpMode: [myComboLoginOpMode getSelectedIndex] + 1];
	[anInstance setUseBarCodeReader: [myComboUseBarCodeReader getSelectedIndex]];
	[anInstance setRemoveBagVerification: [myComboRemoveBagVerification getSelectedIndex]];
	[anInstance setBagTracking: [myComboBagTracking getSelectedIndex]];
	[anInstance setBarCodeReaderComPort: [myComboBarCodeReaderComPort getSelectedIndex] + 1];
	[anInstance setRemoveCashOuterDoor: [myComboRemoveCashOuterDoor getSelectedIndex]];

	if ([anInstance getUseEndDay] != [myComboUseEndDay getSelectedIndex]) 
		myHasChangedUseEndDay = TRUE;

	[anInstance setUseEndDay: [myComboUseEndDay getSelectedIndex]];
	[anInstance setAskBagCode: [myComboAskBagCode getSelectedIndex]];
	[anInstance setAcceptorsCodeType: [myComboAcceptorsCodeType getSelectedIndex] + 1];
	[anInstance setConfirmCode: [myComboConfirmCode getSelectedIndex]];
}

/**/
- (void) onAcceptForm: (id) anInstance
{
	id infoViewer;

	printd("JCimGeneralSettingsEditForm:onAcceptForm\n");

	assert(anInstance != NULL);

	/* Graba el general settings */
	[anInstance applyChanges];

	if ([anInstance getUseBarCodeReader] != myLastUseBarCodeReader || [anInstance getBarCodeReaderComPort] != myLastBarCodeReaderComPort) 
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_BARCODE_RESTART_SYSTEM, "La config lector cod barras cambio. Reinicie el sistema.")];


	if (myHasChangedUseEndDay) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_USE_END_DAY_RESTART_SYSTEM, "Use End Day ha cambiado. El sistema sera reiniciado y puede demorar unos minutos.")];
	
#ifdef __UCLINUX
		// reinicio la aplicacion y el sistema operativo
		infoViewer = [JInfoViewerForm createForm: NULL];
		[infoViewer setCaption: getResourceStringDef(RESID_REBOOTING, "Reiniciando...")];
		[infoViewer showModalForm];
						
		[[CtSystem getInstance] shutdownSystem];
		
		exit(23);
#else
		// reinicio solo la aplicacion
		[JMessageDialog askOKMessageFrom: self withMessage: "Reinicie la aplicacion !!"];
#endif

	}

}


@end

