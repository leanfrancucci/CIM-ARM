#include "JInstaDropSettingsForm.h"
#include "InstaDropManager.h"
#include "MessageHandler.h"
#include "UserManager.h"
#include "UICimUtils.h"
#include "CimManager.h"
#include "JMessageDialog.h"
#include "CimGeneralSettings.h"

#define LOG(args...)// doLog(0,args)
//#define printd(args...)

@implementation  JInstaDropSettingsForm

/**/
- (void) doOpenForm
{
	[super doOpenForm];
	
	myUser = [[UserManager getInstance] getUserLoggedIn];

	[self addLabelFromResource: RESID_SELECT_KEY_LABEL default: "Seleccionar Tecla:"];

	myGrid = [JGrid new];
	[myGrid setHeight: 2];
	[myGrid setOwnObjects: FALSE];
	[myGrid addItemsFromCollection: [[InstaDropManager getInstance] getInstaDrops]];

	[self addFormComponent: myGrid];
}

/**/
- (void) onMenu1ButtonClick
{
	[self closeForm];
}

/**/
- (void) onMenu2ButtonClick
{
	CIM_CASH cimCash;
	INSTA_DROP instaDrop;
	CASH_REFERENCE reference = NULL;
	char envelopeNumber[50];
	char applyTo[50];
	USER user;

	*envelopeNumber = '\0';
	*applyTo = '\0';	

	if (myGrid == NULL) return;
	if ([myGrid getSelectedItem] == NULL) return;

	instaDrop = [myGrid getSelectedItem];

/*	// Deslogueo al usuario si corresponde
	if ([instaDrop getUser] == myUser) {
*/
	if (![instaDrop isAvaliable]) {

		if ([JMessageDialog askYesNoMessageFrom: self 
				withMessage: getResourceStringDef(RESID_REMOVE_INSTA_DROP_QUESTION, "Confirma la eliminacion del Deposito Instantaneo?")] == JDialogResult_NO) return;

		[[InstaDropManager getInstance] clearInstaDrop: [instaDrop getFunctionKey]];	

	// O creo un nuevo Insta Drop para el usuario actual
	} else {

		cimCash = [UICimUtils selectAutoCimCash: self];
		if (!cimCash) return;

		// El Cash ya se esta utilizando para un Extended Drop
		if ([[CimManager getInstance] getExtendedDrop: cimCash] != NULL) {
			[JMessageDialog askOKMessageFrom: self 
				withMessage: getResourceStringDef(RESID_CASH_ALREADY_USE_EXTENDED, "El Cash ya se encuentra en uso por un Deposito Extendido.")];
			return;	
		}

		user = [UICimUtils selectUserWithDropPermission: self];
		if (user == NULL) return;

		// Solicito la referencia (si es que las utiliza)
		if ([[CimGeneralSettings getInstance] getUseCashReference]) {
			reference = [UICimUtils selectCashReference: self];
			if (reference == NULL) return;
		}
		
  	// Solicito el APPLY TO (si corresponde)
  	if ([[CimGeneralSettings getInstance] getAskApplyTo]) {
  
  		if (![UICimUtils askApplyTo: self
  			applyTo: applyTo
  			title: getResourceStringDef(RESID_INSTA_DROP, "Deposito Rapido")
  			description: getResourceStringDef(RESID_APPLIED_TO, "Aplicar a:")]) return;
  	}

		// Configuro el Insta Drop
		[[InstaDropManager getInstance] setInstaDrop: [instaDrop getFunctionKey] 
			user: user 
			cimCash: cimCash 
			cashReference: reference
			envelopeNumber: envelopeNumber
      applyTo: applyTo];

	}

	[myGrid paintComponent];

	[self doChangeStatusBarCaptions];
}

/**/
- (char *) getCaption1
{	
	return getResourceStringDef(RESID_BACK_KEY, "atras");
}

/**/
- (char *) getCaption2
{	
	// Si la fila donde estoy parado corresponde al usuario actual permito desloguearlo
	if (myGrid != NULL && [myGrid getSelectedItem] && ![[myGrid getSelectedItem] isAvaliable])
		return getResourceStringDef(RESID_REMOVE_LABEL, "elimin");

	// Si la fila donde estoy parado esta disponible, permito seleccionarla
	if (myGrid != NULL && [myGrid getSelectedItem] && [[myGrid getSelectedItem] isAvaliable])
		return getResourceStringDef(RESID_ENTER, "entrar");

	return NULL;
}


@end
