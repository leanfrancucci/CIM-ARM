#include "UserInterfaceExcepts.h"
#include "JBoxModelChangeEditForm.h"
#include "JMessageDialog.h"
#include "JExceptionForm.h"
#include "MessageHandler.h"
#include "BoxModel.h"
#include "JInfoViewerForm.h"
#include "CtSystem.h"
#include "CimManager.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JBoxModelChangeEditForm
static char myCaption2[] = "grabar";
static char myCaption1[] = "";

/**/
- (void) phisicalModel_onSelect;
-(void) saveModel;

/**/
- (void) setShowCancel: (BOOL) aValue
{	
	myShowCancel = aValue;

	if (myShowCancel)
		strcpy(myCaption1,getResourceStringDef(RESID_CANCEL_KEY, "cancel"));
	else strcpy(myCaption1,"");
}

/**/
- (void) setIsViewMode: (BOOL) aValue
{
	myIsViewMode = aValue;
}

/**/
- (int) getBoxModel
{
	id box = NULL;
	char boxModel[60];

	box = [[[CimManager getInstance] getCim] getBoxById: 1];
	if (!box) return PhisicalModel_Box2ED2V1M;
	strcpy(boxModel, trim([box getBoxModel]));
	if (strlen(boxModel) == 0) return PhisicalModel_Box2ED2V1M;
	
	// busco el modelo de caja
	if (strstr(boxModel, "Box2ED2V1M")) return PhisicalModel_Box2ED2V1M;
	if (strstr(boxModel, "Box2ED1V1M")) return PhisicalModel_Box2ED1V1M;
	if (strstr(boxModel, "Box2EDI2V1M")) return PhisicalModel_Box2EDI2V1M;
	if (strstr(boxModel, "Box2EDI1V1M")) return PhisicalModel_Box2EDI1V1M;
	if (strstr(boxModel, "Box1ED2V1M")) return PhisicalModel_Box1ED2V1M;
	if (strstr(boxModel, "Box1ED1V1M")) return PhisicalModel_Box1ED1V1M;
	if (strstr(boxModel, "Box1ED1M")) return PhisicalModel_Box1ED1M;
	if (strstr(boxModel, "Box1D2V1M")) return PhisicalModel_Box1D2V1M;
	if (strstr(boxModel, "Box1D1V1M")) return PhisicalModel_Box1D1V1M;
	if (strstr(boxModel, "Box1D1M")) return PhisicalModel_Box1D1M;
	if (strstr(boxModel, "FLEX")) return PhisicalModel_Flex;
	
	// por las dudas que no haya entrado en ningun if
	return PhisicalModel_Box2ED2V1M;

}

/**/
- (int) getValModel: (int) aValId
{
	id box = NULL;
	id acceptorSett = NULL;
	char acceptorModel[60];

	// si aun el modelo de caja no fue seteado retorno 0
	box = [[[CimManager getInstance] getCim] getBoxById: 1];
	if (strlen(trim([box getBoxModel])) == 0) return ValidatorModel_JCM_PUB11_BAG;

	// obtengo el modelo de validador
	acceptorSett = [[[CimManager getInstance] getCim] getAcceptorSettingsById: aValId];

	if (!acceptorSett) return ValidatorModel_JCM_PUB11_BAG;
	strcpy(acceptorModel,trim([acceptorSett getAcceptorModel]));
	if (strlen(acceptorModel) == 0) return ValidatorModel_JCM_PUB11_BAG;

	if (strstr(acceptorModel, "PUB11|BAG|")) return ValidatorModel_JCM_PUB11_BAG;
	if (strstr(acceptorModel, "WBA|SS|")) return ValidatorModel_JCM_WBA_Stacker;
	if (strstr(acceptorModel, "BNF|SS|")) return ValidatorModel_JCM_BNF_Stacker;
	if (strstr(acceptorModel, "BNF|BAG|")) return ValidatorModel_JCM_BNF_BAG;
	if (strstr(acceptorModel, "FRONTLOAD MW|V|")) return ValidatorModel_CC_CS_Stacker;
	if (strstr(acceptorModel, "CCB|BAG|")) return ValidatorModel_CC_CCB_BAG;
	if (strstr(acceptorModel, "S66 BULK|H|")) return ValidatorModel_MEI_S66_Stacker;

	// por las dudas que no haya entrado en ningun if
	return ValidatorModel_JCM_PUB11_BAG;

}

/**/
- (void) onCreateForm
{
  [super onCreateForm];

	myShowVal1 = TRUE;
	myShowVal2 = TRUE;
	strcpy(myCaption2, getResourceStringDef(RESID_NEXT_KEY, "sig."));

	// Modelo fisico
	myLabelPhisicalModel = [JLabel new];
	[myLabelPhisicalModel setCaption: getResourceStringDef(RESID_PHISICAL_MODEL_LABEL, "Modelo Fisico:")];
	[self addFormComponent: myLabelPhisicalModel];

	[self addFormEol];

	myComboPhisicalModel = [JCombo new];
	[myComboPhisicalModel setWidth: 20];
	[myComboPhisicalModel setHeight: 1];
	[myComboPhisicalModel addString: "Box2ED2V1M"];
	[myComboPhisicalModel addString: "Box2ED1V1M"];
	[myComboPhisicalModel addString: "Box2EDI2V1M"];
	[myComboPhisicalModel addString: "Box2EDI1V1M"];
	[myComboPhisicalModel addString: "Box1ED2V1M"];
	[myComboPhisicalModel addString: "Box1ED1V1M"];
	[myComboPhisicalModel addString: "Box1ED1M"];
	[myComboPhisicalModel addString: "Box1D2V1M"];
	[myComboPhisicalModel addString: "Box1D1V1M"];
	[myComboPhisicalModel addString: "Box1D1M"];
	[myComboPhisicalModel addString: "FLEX"];
	[myComboPhisicalModel setSelectedIndex: [self getBoxModel]];
	[myComboPhisicalModel setOnSelectAction: self action: "phisicalModel_onSelect"];

	// si ya hay movimientos generados no lo dejo cambiar el modelo fisico. Solo los validadores.
	if ([[[CimManager getInstance] getCim] hasMovements])
		[myComboPhisicalModel setReadOnly: TRUE];

	[self addFormComponent: myComboPhisicalModel];

	[self addFormNewPage];

	// modelo de validador 1
	myLabelValModel = [JLabel new];
	[myLabelValModel setCaption: getResourceStringDef(RESID_VAL1_MODEL_LABEL, "Modelo Val 1:")];
	[self addFormComponent: myLabelValModel];

	[self addFormEol];

	myComboValModel = [JCombo new];
	[myComboValModel setWidth: 20];
	[myComboValModel setHeight: 1];
	[myComboValModel addString: "JCM-PUB11-BAG"];
	[myComboValModel addString: "JCM-WBA-Stacker"];
	[myComboValModel addString: "JCM-BNF-Stacker"];
	[myComboValModel addString: "JCM-BNF-BAG"];
	[myComboValModel addString: "CC-CS-Stacker"];
	[myComboValModel addString: "CC-CCB-BAG"];
	[myComboValModel addString: "MEI-S66-Stacker"];
	[myComboValModel setSelectedIndex: [self getValModel: 1]];
	[self addFormComponent: myComboValModel];

	[self addFormNewPage];

	// modelo de validador 2
	myLabelVal2Model = [JLabel new];
	[myLabelVal2Model setCaption: getResourceStringDef(RESID_VAL2_MODEL_LABEL, "Modelo Val 2:")];
	[self addFormComponent: myLabelVal2Model];

	[self addFormEol];

	myComboVal2Model = [JCombo new];
	[myComboVal2Model setWidth: 20];
	[myComboVal2Model setHeight: 1];
	[myComboVal2Model addString: "JCM-PUB11-BAG"];
	[myComboVal2Model addString: "JCM-WBA-Stacker"];
	[myComboVal2Model addString: "JCM-BNF-Stacker"];
	[myComboVal2Model addString: "JCM-BNF-BAG"];
	[myComboVal2Model addString: "CC-CS-Stacker"];
	[myComboVal2Model addString: "CC-CCB-BAG"];
	[myComboVal2Model addString: "MEI-S66-Stacker"];
	[myComboVal2Model setSelectedIndex: [self getValModel: 2]];
	[self addFormComponent: myComboVal2Model];

}

/**/
- (void) doOpenForm
{
	if (myIsViewMode) {
		// si ya hay movimientos generados no lo dejo cambiar el modelo fisico. Solo los validadores.
		[myComboPhisicalModel setReadOnly: TRUE];
		[myComboValModel setReadOnly: TRUE];
		[myComboVal2Model setReadOnly: TRUE];
	} else {
		if (![[[CimManager getInstance] getCim] hasMovements])
			[myComboPhisicalModel setReadOnly: FALSE];

		[myComboValModel setReadOnly: FALSE];
		[myComboVal2Model setReadOnly: FALSE];
	}

	[self phisicalModel_onSelect];
	[self paintComponent];
}

/**/
- (void) phisicalModel_onSelect
{

	// deshabilito o habilito los combos de validadores segun el modelo de caja elegido
	if (myShowCancel)
		strcpy(myCaption1,getResourceStringDef(RESID_CANCEL_KEY, "cancel"));
	else strcpy(myCaption1,"");

	switch ([myComboPhisicalModel getSelectedIndex]) {

		case PhisicalModel_Box2ED2V1M:
		case PhisicalModel_Box2EDI2V1M:
		case PhisicalModel_Box1D2V1M:
		case PhisicalModel_Box1ED2V1M:
		case PhisicalModel_Flex:
				// habilito val 1 y val 2
				myShowVal1 = TRUE;
				myShowVal2 = TRUE;
				strcpy(myCaption2,getResourceStringDef(RESID_NEXT_KEY, "sig."));
			break;

		case PhisicalModel_Box1ED1M:
		case PhisicalModel_Box1D1M:
				// deshabilito val 1 y val 2
				myShowVal1 = FALSE;
				myShowVal2 = FALSE;

				if (!myIsViewMode)
					strcpy(myCaption2,getResourceStringDef(RESID_SAVE_KEY, "grabar"));
				else strcpy(myCaption2,"");
			break;

		case PhisicalModel_Box2ED1V1M:
		case PhisicalModel_Box2EDI1V1M:
		case PhisicalModel_Box1D1V1M:
		case PhisicalModel_Box1ED1V1M:
				// deshabilito val 2
				myShowVal1 = TRUE;
				myShowVal2 = FALSE;

				strcpy(myCaption2,getResourceStringDef(RESID_NEXT_KEY, "sig."));
			break;
	}

	[self doChangeStatusBarCaptions];
}

/**/
- (char *) getCaptionX
{
	if (myIsViewMode)
		return getResourceStringDef(RESID_UPDATE_KEY, "modif.");
	else return "";
}

/**/
- (char *) getCaption1
{
	return myCaption1;
}

/**/
- (char*) getCaption2
{
	return myCaption2;
}

/**/
- (void) onMenu1ButtonClick
{

	if ([self getFormFocusedComponent] == myComboVal2Model) {
		strcpy(myCaption2,getResourceStringDef(RESID_NEXT_KEY, "sig."));
		strcpy(myCaption1, getResourceStringDef(RESID_BACK_KEY, "atras"));
		[self focusFormPreviousComponent];
		[self doChangeStatusBarCaptions];
	} else {
		if ([self getFormFocusedComponent] == myComboValModel) {
			strcpy(myCaption2,getResourceStringDef(RESID_NEXT_KEY, "sig."));
			if (myShowCancel)
				strcpy(myCaption1,getResourceStringDef(RESID_CANCEL_KEY, "cancel"));
			else strcpy(myCaption1,"");
			[self focusFormPreviousComponent];
			[self doChangeStatusBarCaptions];
		} else {
			if ( ([self getFormFocusedComponent] == myComboPhisicalModel) && (myShowCancel) )
				[self closeForm];
		}
	}
}

/**/
- (void) onMenu2ButtonClick
{

	if ([self getFormFocusedComponent] == myComboPhisicalModel) {
		if (myShowVal1) {
			if (myShowVal2)
				strcpy(myCaption2,getResourceStringDef(RESID_NEXT_KEY, "sig."));
			else {
				if (!myIsViewMode)
					strcpy(myCaption2,getResourceStringDef(RESID_SAVE_KEY, "grabar"));
				else strcpy(myCaption2,"");
			}

			strcpy(myCaption1, getResourceStringDef(RESID_BACK_KEY, "atras"));

			[self focusFormNextComponent];
			[self doChangeStatusBarCaptions];
		} else if (!myIsViewMode) { [self saveModel]; }
	} else {
		if ([self getFormFocusedComponent] == myComboValModel) {
			if (myShowVal2) {
				if (!myIsViewMode)
					strcpy(myCaption2,getResourceStringDef(RESID_SAVE_KEY, "grabar"));
				else strcpy(myCaption2,"");

				strcpy(myCaption1, getResourceStringDef(RESID_BACK_KEY, "atras"));

				[self focusFormNextComponent];
				[self doChangeStatusBarCaptions];
			} else if (!myIsViewMode) { [self saveModel]; }
		} else {
			if (!myIsViewMode) {
				// guardo los cambios
				[self saveModel];
			}
		}
	}

}

/**/
- (void) onMenuXButtonClick
{
	if (myIsViewMode) {
		myIsViewMode = FALSE;

		// si ya hay movimientos generados no lo dejo cambiar el modelo fisico. Solo los validadores.
		if (![[[CimManager getInstance] getCim] hasMovements])
			[myComboPhisicalModel setReadOnly: FALSE];

		[myComboValModel setReadOnly: FALSE];
		[myComboVal2Model setReadOnly: FALSE];

		if (strlen(myCaption2) == 0)
			strcpy(myCaption2,getResourceStringDef(RESID_SAVE_KEY, "grabar"));

		[self paintComponent];
		[self doChangeStatusBarCaptions];
	}
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed
{
	if (!anIsPressed)
			return FALSE;

	if ((aKey == UserInterfaceDefs_KEY_UP) || (aKey == UserInterfaceDefs_KEY_DOWN))
		return TRUE;

	[super doKeyPressed: aKey isKeyPressed: anIsPressed];
}

-(void) saveModel
{
	id boxModel;
	id infoViewer;
	JFORM processForm = NULL;

	if ([JMessageDialog askYesNoMessageFrom: self withMessage: getResourceStringDef(RESID_SAVE_MODEL_QUESTION, "Guardar modelo ?")] == JDialogResult_NO) return;

	printf("saveModel *************\n");

  TRY
    processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];

		boxModel = [BoxModel new];
		[boxModel setPhisicalModel: [myComboPhisicalModel getSelectedIndex]];

		printf("index = %d\n", [myComboPhisicalModel getSelectedIndex]);

		if (myShowVal1) [boxModel setVal1Model: [myComboValModel getSelectedIndex]];
		if (myShowVal2) [boxModel setVal2Model: [myComboVal2Model getSelectedIndex]];

        printf("guarda el modelo\n");
        [boxModel save];

  FINALLY

        [processForm closeProcessForm];
        [processForm free];
		[boxModel free];

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

  END_TRY

}

@end

