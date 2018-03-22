#include "JInstaDropForm.h"
#include "InstaDropManager.h"
#include "MessageHandler.h"
#include "UserManager.h"
#include "UICimUtils.h"
#include "JSystem.h"
#include "JVerifyBillForm.h"
#include "CimManager.h"
#include "JMessageDialog.h"

#define LOG(args...)// doLog(0,args)
//#define printd(args...)

@implementation  JInstaDropForm

/**/
- (void) onCreateForm
{
	[super onCreateForm];

	myLabelMsg = [self addLabelFromResource: RESID_PRESS_INSTA_KEY default: "Pres. tecla Rapida.."];
	myIsApplicationForm = TRUE;
	myGrid = [JGrid new];
	[myGrid setHeight: 2];
	[myGrid setOwnObjects: FALSE];
	[self addFormComponent: myGrid];
}

/**/
- (void) setIsApplicationForm: (BOOL) aValue
{
	myIsApplicationForm = aValue;
}

/**/
- (void) onMenu1ButtonClick
{
	if (myIsApplicationForm) [[JSystem getInstance] sendActivateMainApplicationFormMessage];
	else [self closeForm];
}

/**/
- (void) onMenuXButtonClick
{
	if (myIsApplicationForm) [[JSystem getInstance] sendActivateMainApplicationFormMessage];
}

/**/
- (void) startDepositWithInstaDrop: (INSTA_DROP) aInstaDrop
{

	if (![UICimUtils canMakeDeposits: self]) return;

	// controlo que la puerta este cerrada
	if ([[[aInstaDrop getCimCash] getDoor] getDoorState] == DoorState_OPEN) {
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_YOU_MUST_CLOSE_VALIDATED_DOOR, "Primero debe cerrar la puerta validada!")];
		return;
	}

	[[CimManager getInstance] checkCimCashState: [aInstaDrop getCimCash]];

	[UICimUtils startDeposit: self user: [aInstaDrop getUser] 
		cimCash: [aInstaDrop getCimCash] 
		cashReference: [aInstaDrop getCashReference]
		envelopeNumber: [aInstaDrop getEnvelopeNumber]
    applyTo: [aInstaDrop getApplyTo]];

	if (myIsApplicationForm) [[JSystem getInstance] sendActivateMainApplicationFormMessage];
	else [self closeForm];
}

/**/
- (void) onMenu2ButtonClick
{
	INSTA_DROP instaDrop;

	instaDrop = [myGrid getSelectedItem];
	if (instaDrop == NULL || [instaDrop isAvaliable]) return;

	[self startDepositWithInstaDrop: instaDrop];
}



/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed
{
	INSTA_DROP instaDrop;
	JFORM form;

	if (!anIsPressed)
			return FALSE;

	// 
	if (aKey == '0') {

		if (![UICimUtils canMakeDeposits: self]) return TRUE;
	
		form = [JVerifyBillForm createForm: self];
		[form showModalForm];
		[form free];

		if (!myIsApplicationForm) [self closeForm];

		return TRUE;
	}

	// Manejo las teclas del 1..9 para directamente abrir
	// el formulario de deposito correspondiente (siempre y cuando exista un
	// Insta Drop activo para esa tecla)
	if (aKey >= '1' && aKey <= '9') {

		instaDrop = [[InstaDropManager getInstance] getInstaDropForKey: aKey - 48];
		if (instaDrop == NULL || [instaDrop isAvaliable]) return TRUE;

		[self startDepositWithInstaDrop: instaDrop];

		return TRUE;
	
	}

	return [super doKeyPressed: aKey isKeyPressed: anIsPressed];
}

/**/
- (char *) getCaption1
{	
	return getResourceStringDef(RESID_BACK_KEY, "atras");
}

/**/
- (char *) getCaptionX
{	
	if (myIsApplicationForm)return getResourceStringDef(RESID_MENU, "menu");
	return NULL;
}

/**/
- (char *) getCaption2
{	
	return getResourceStringDef(RESID_ENTER, "entrar");
}

/**/
- (void) onActivateForm
{
	COLLECTION list;
	
	[myLabelMsg setCaption: getResourceStringDef(RESID_PRESS_INSTA_KEY, "Pres. tecla Rapida..")];
	
	[myGrid clearItems];
	
	list = [[InstaDropManager getInstance] getActiveInstaDrops];
	[myGrid addItemsFromCollection: list];
	[myGrid paintComponent];
	
	[list free];
}

@end
