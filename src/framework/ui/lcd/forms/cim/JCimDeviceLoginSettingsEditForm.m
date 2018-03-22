#include "JCimDeviceLoginSettingsEditForm.h"
#include "CimGeneralSettings.h"
#include "MessageHandler.h"
#include "JMessageDialog.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)

@implementation  JCimDeviceLoginSettingsEditForm


/**/
- (void) onCreateForm
{
	char aux[41];
	[super onCreateForm];
	printd("JCimDeviceLoginSettingsEditForm:onCreateForm\n");

	// Combo Login Device Type
	[self addFormNewPage];
	sprintf(aux, "%s:", getResourceStringDef(RESID_CIM_GeneralSettings_LOGIN_DEV_TYPE, "Tipo disp. login"));
	[self addLabel: aux];
	myComboLoginDevType = [JCombo new];
	[myComboLoginDevType addString: getResourceStringDef(RESID_CIM_GeneralSettings_LOGIN_DEV_TYPE_NONE, "NINGUNO")];
	[myComboLoginDevType addString: getResourceStringDef(RESID_CIM_GeneralSettings_LOGIN_DEV_TYPE_DALLAS_KEY, "LLAVE DALLAS")];
	[myComboLoginDevType addString: getResourceStringDef(RESID_CIM_GeneralSettings_LOGIN_DEV_TYPE_SWIPE_CARD_R, "LECTOR TARJETA")];
	[myComboLoginDevType setOnSelectAction: self 	action: "deviceType_onSelect"];
	[self addFormComponent: myComboLoginDevType];

	// Combo Login Device COM Port
	[self addFormNewPage];
	myLabelLoginDevComPort = [JLabel new];
	sprintf(aux, "%s:", getResourceStringDef(RESID_CIM_GeneralSettings_LOGIN_DEV_COM_PORT, "COM disp. login"));
	if (strlen(aux) > JComponent_MAX_WIDTH) {
		[myLabelLoginDevComPort setHeight: 2];
		[myLabelLoginDevComPort setWidth: 20];
		[myLabelLoginDevComPort setWordWrap: TRUE];
	}
	[myLabelLoginDevComPort setCaption: aux];
	[self addFormComponent: myLabelLoginDevComPort];
	[self addFormEol];

	myComboLoginDevComPort = [JCombo new];
	[myComboLoginDevComPort addString: "1"];
	[myComboLoginDevComPort addString: "2"];
	[self addFormComponent: myComboLoginDevComPort];

	// Track de tarjeta
	[self addFormNewPage];
	myLabelSwipeCardTrack = [JLabel new];
	sprintf(aux, "%s:", getResourceStringDef(RESID_CIM_GeneralSettings_SWIPE_CARD_TRACK, "Track tarjeta mag."));
	if (strlen(aux) > JComponent_MAX_WIDTH) {
		[myLabelSwipeCardTrack setHeight: 2];
		[myLabelSwipeCardTrack setWidth: 20];
		[myLabelSwipeCardTrack setWordWrap: TRUE];
	}
	[myLabelSwipeCardTrack setCaption: aux];
	[self addFormComponent: myLabelSwipeCardTrack];
	[self addFormEol];

	myComboSwipeCardTrack = [JCombo new];
	[myComboSwipeCardTrack addString: "1"];
	[myComboSwipeCardTrack addString: "2"];
	[myComboSwipeCardTrack addString: "3"];
	[self addFormComponent: myComboSwipeCardTrack];

	// Offset de tarjeta
	[self addFormNewPage];
	myLabelSwipeCardOffset = [JLabel new];
	sprintf(aux, "%s:", getResourceStringDef(RESID_CIM_GeneralSettings_SWIPE_CARD_OFFSET, "Offset tarjeta mag."));
	if (strlen(aux) > JComponent_MAX_WIDTH) {
		[myLabelSwipeCardOffset setHeight: 2];
		[myLabelSwipeCardOffset setWidth: 20];
		[myLabelSwipeCardOffset setWordWrap: TRUE];
	}
	[myLabelSwipeCardOffset setCaption: aux];
	[self addFormComponent: myLabelSwipeCardOffset];
	[self addFormEol];

	myTextSwipeCardOffset = [JText new];
  [myTextSwipeCardOffset setWidth: 3];
	[myTextSwipeCardOffset setNumericMode: TRUE];
	[self addFormComponent: myTextSwipeCardOffset];

	// Cantidad a leer en tarjeta
	[self addFormNewPage];
	myLabelSwipeCardReadQty = [JLabel new];
	sprintf(aux, "%s:", getResourceStringDef(RESID_CIM_GeneralSettings_SWIPE_CARD_READ_QTY, "Cant lectura tarjeta"));
	if (strlen(aux) > JComponent_MAX_WIDTH) {
		[myLabelSwipeCardReadQty setHeight: 2];
		[myLabelSwipeCardReadQty setWidth: 20];
		[myLabelSwipeCardReadQty setWordWrap: TRUE];
	}
	[myLabelSwipeCardReadQty setCaption: aux];
	[self addFormComponent: myLabelSwipeCardReadQty];
	[self addFormEol];

	myTextSwipeCardReadQty = [JText new];
  [myTextSwipeCardReadQty setWidth: 3];
	[myTextSwipeCardReadQty setNumericMode: TRUE];
	[self addFormComponent: myTextSwipeCardReadQty];

 	[self setConfirmAcceptOperation: TRUE];
}

/**/
- (void) onCancelForm: (id) anInstance
{
	printd("JCimDeviceLoginSettingsEditForm:onAcceptForm\n");

	assert(anInstance != NULL);

	[anInstance restore];
}

/**/
- (void) onModelToView: (id) anInstance
{
	printd("JCimDeviceLoginSettingsEditForm:onModelToView\n");

	assert(anInstance != NULL);

	[myComboLoginDevType setSelectedIndex: [anInstance getLoginDevType] - 1];
	[myComboLoginDevComPort setSelectedIndex: [anInstance getLoginDevComPort] - 1];
	[myComboSwipeCardTrack setSelectedIndex: [anInstance getSwipeCardTrack] - 1];
	[myTextSwipeCardOffset setLongValue: [anInstance getSwipeCardOffset]];
	[myTextSwipeCardReadQty setLongValue: [anInstance getSwipeCardReadQty]];

	// almaceno los valores antes para saber si al grabar se modificaron
	myLastLoginDevType = [anInstance getLoginDevType];
	myLastLoginDevComPort = [anInstance getLoginDevComPort];

	[self deviceType_onSelect];
}

/**/
- (void) onViewToModel: (id) anInstance
{
	printd("JCimDeviceLoginSettingsEditForm:onViewToModel\n");

	assert(anInstance != NULL);

	[anInstance setLoginDevType: [myComboLoginDevType getSelectedIndex] + 1];
	[anInstance setLoginDevComPort: [myComboLoginDevComPort getSelectedIndex] + 1];
	[anInstance setSwipeCardTrack: [myComboSwipeCardTrack getSelectedIndex] + 1];
	[anInstance setSwipeCardOffset: [myTextSwipeCardOffset getLongValue]];
	[anInstance setSwipeCardReadQty: [myTextSwipeCardReadQty getLongValue]];
}

/**/
- (void) onAcceptForm: (id) anInstance
{
	printd("JCimDeviceLoginSettingsEditForm:onAcceptForm\n");

	assert(anInstance != NULL);

	/* Graba el general settings */
	[anInstance applyChanges];

	if ([anInstance getLoginDevType] != myLastLoginDevType || [anInstance getLoginDevComPort] != myLastLoginDevComPort) 
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_LOGIN_DEVICE_RESTART_SYSTEM, "La config. disp. de login cambio. Reinicie el sistema.")];
}

/**/
- (void) deviceType_onSelect
{

	[myLabelLoginDevComPort setVisible: FALSE];
	[myComboLoginDevComPort setVisible: FALSE];

	[myLabelSwipeCardTrack setVisible: FALSE];
	[myComboSwipeCardTrack setVisible: FALSE];

	[myLabelSwipeCardOffset setVisible: FALSE];
	[myTextSwipeCardOffset setVisible: FALSE];

	[myLabelSwipeCardReadQty setVisible: FALSE];
	[myTextSwipeCardReadQty setVisible: FALSE];

	if (([myComboLoginDevType getSelectedIndex] + 1) == LoginDevType_DALLAS_KEY) {
	
		[myLabelLoginDevComPort setVisible: TRUE];
		[myComboLoginDevComPort setVisible: TRUE];

	}	else if (([myComboLoginDevType getSelectedIndex] + 1) == LoginDevType_SWIPE_CARD_READER) {

		[myLabelLoginDevComPort setVisible: TRUE];
		[myComboLoginDevComPort setVisible: TRUE];

		[myLabelSwipeCardTrack setVisible: TRUE];
		[myComboSwipeCardTrack setVisible: TRUE];
	
		[myLabelSwipeCardOffset setVisible: TRUE];
		[myTextSwipeCardOffset setVisible: TRUE];
	
		[myLabelSwipeCardReadQty setVisible: TRUE];
		[myTextSwipeCardReadQty setVisible: TRUE];

	}

	[self focusFormPreviousComponent];

	[self paintComponent];
}

@end

