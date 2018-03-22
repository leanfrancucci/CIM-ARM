#include "JRegionalSettingsEditForm.h"
#include "RegionalSettings.h"
#include "UserInterfaceExcepts.h"
#include "CtSystem.h"
#include "SettingsExcepts.h"
#include "JSystem.h"
#include "PrinterSpooler.h"
#include "JMessageDialog.h"
#include "UserManager.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation  JRegionalSettingsEditForm

/**/
- (void) onCreateForm
{
	char number[10];
	int i;
	char msgLang[20];

	[super onCreateForm];
	printd("JRegionalSettingsEditForm:onCreateForm\n");

  realTime = 0;
  realDate = 0;
	wasChangedTimeZone = FALSE;
  
	// Date
	myLabelDate = [self addLabelFromResource: RESID_DATE default: "Fecha:"];
	myDateDateText = [JDate new];
	[myDateDateText setJDateFormat: [[RegionalSettings getInstance] getDateFormat]];
	[myDateDateText setSystemTimeMode:TRUE];
	[self addFormComponent: myDateDateText];
	[self addFormNewPage];
	
	// Time
	myLabelTime = [self addLabelFromResource: RESID_HOUR default: "Hora:"];
	myTimeTimeText = [JTime new];
	[myTimeTimeText setSystemTimeMode:TRUE];
	[self addFormComponent: myTimeTimeText];
	[self addFormNewPage];
  	
	// Time Zone
	myLabelTimeZone = [self addLabelFromResource: RESID_TIME_ZONE default: "Zona Horaria:"];
	myComboTimeZone = [JCombo new];
	for (i=-12; i<=12; i++) {
		sprintf(number, "%d", i);
		[myComboTimeZone addString: number];
	}
	[self addFormComponent: myComboTimeZone];
	[self addFormNewPage];

	// Idioma
	myLabelLanguage = [self addLabelFromResource: RESID_LANGUAGE default: "Idioma:"];
	myComboLanguage = [JCombo new];
	sprintf(msgLang,"Espa%col",'\xF1');
	[myComboLanguage addString: msgLang];
	[myComboLanguage addString: "English"];
	sprintf(msgLang,"Fran%cais",'\xC7');
	[myComboLanguage addString: msgLang];
	[self addFormComponent: myComboLanguage];
	[self addFormNewPage];

	// Formato de fecha
	myLabelDateFormat = [self addLabelFromResource: RESID_DATE_FORMAT default: "Formato fecha:"];
	myComboDateFormat = [JCombo new];
	[myComboDateFormat addString: "DD/MM/YY"];
	[myComboDateFormat addString: "MM/DD/YY"];
	[self addFormComponent: myComboDateFormat];


	[self setConfirmAcceptOperation: TRUE];
}

/**/
- (void) onCancelForm: (id) anInstance
{

	printd("JRegionalSettingsEditForm:onAcceptForm\n");

	assert(anInstance != NULL);
	
	[anInstance restore];
}

/**/
- (void) onModelToView: (id) anInstance
{
	int timeZ;
	printd("JRegionalSettingsEditForm:onModelToView\n");

	assert(anInstance != NULL);

	// Time Zone
	timeZ = ([anInstance getTimeZone] / 3600);
	[myComboTimeZone setSelectedIndex: (12+timeZ)];
	
	// Idioma
	[myComboLanguage setSelectedIndex: [anInstance getLanguage] - 1];

	// Formato fecha
	[myComboDateFormat setSelectedIndex: [anInstance getDateFormat] - 1];

	myOriginalLanguage = [anInstance getLanguage];
}

/**/
- (void) onViewToModel: (id) anInstance
{
	int timeZ;
	int lastTimeZone;
	//id userLoged = NULL;
	printd("JRegionalSettingsEditForm:onViewToModel\n");

	assert(anInstance != NULL);

	// Time Zone
	lastTimeZone = [anInstance getTimeZone];
	timeZ = ((-12 + [myComboTimeZone getSelectedIndex]) * 3600);
	[anInstance setTimeZone: timeZ];

	if (lastTimeZone != [anInstance getTimeZone])
		wasChangedTimeZone = TRUE;

	// Idioma
	[anInstance setLanguage: [myComboLanguage getSelectedIndex] + 1];

	// Formato fecha
	[anInstance setDateFormat: [myComboDateFormat getSelectedIndex] + 1];

}

/**/
- (void) onAcceptForm: (id) anInstance
{
	id userAdmin = NULL;
	id userLoged = NULL;
	
	printd("JRegionalSettingsEditForm:onAcceptForm\n");

	assert(anInstance != NULL);

  if ( (![myDateDateText isDateCorrect] ) || (![myTimeTimeText isTimeCorrect]) )
		THROW(UI_INVALID_DATE_TIME_EX);
	
  /* Graba el regional settings */
  [anInstance applyChanges];
  
  // Cambio el idioma del menu y de los reportes
	if ([anInstance getLanguage] != myOriginalLanguage) {
		
		// actualizo el idioma del ADMIN
		userAdmin = [[UserManager getInstance] getUser: 1];
		if (userAdmin) {
			[userAdmin setLanguage: [anInstance getLanguage]];
			[userAdmin applyChanges];
		}

		// refresco el menu solo si el usuario logueado es el admin, ya que el idioma del
		// admin depende del idioma seteado en regional settings
		userLoged = [[UserManager getInstance] getUserLoggedIn];
		if ((userLoged) && ([userLoged getUserId] == 1)) {
			[[MessageHandler getInstance] setCurrentLanguage: [anInstance getLanguage]];
			[[InputKeyboardManager getInstance] setCurrentLanguage: [anInstance getLanguage]];
  		[[PrinterSpooler getInstance] setReportPathByLanguage: [anInstance getLanguage]];
			[[JSystem getInstance] onRefreshMenu];
		}
	}
	
  // Date time
  if ((realTime != [myTimeTimeText getDateTimeValue]) || (realDate != [myDateDateText getDateValue]))
	  [anInstance setDateTime: [myDateDateText getDateValue] + [myTimeTimeText getDateTimeValue]];

	// Cambio el formato de fecha / hora
	[myDateDateText setJDateFormat: [anInstance getDateFormat]];

	if (wasChangedTimeZone) {
		wasChangedTimeZone = FALSE;
		[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_TIME_ZONE_RESTART_SYSTEM, "La zona horaria ha cambiado. Reinicie el sistema.")];
	}

}

/**/
- (char*) getCaptionX
{
  return NULL;
}

/**
 * Si esta en modo VIEW entra en modo EDIT.
 * Si esta en modo EDIT, acepta el formulario y entra en modo VIEW
 */
- (void) onMenu2ButtonClick
{
	BOOL mustPaint;
	
	mustPaint = FALSE;
		
	[self lockWindowsUpdate];
	
	TRY

			/* Paso a modo edicion ... */
			if (myFormMode == JEditFormMode_VIEW && myIsEditable) {
			
				[self doChangeFormMode: JEditFormMode_EDIT];
				mustPaint = TRUE;
				
				// guardo la hora actual para ver si se modifica o no
				realTime = [myTimeTimeText getDateTimeValue];
				realDate = [myDateDateText getDateValue];
				
			} else { 	/* Valida, acepta y pasa a modo view */
			
				if (myFormMode == JEditFormMode_EDIT) {
 					if ([self doAcceptForm])
						[self doChangeFormMode: JEditFormMode_VIEW];
				}				
			}
		
	FINALLY
		
      [self unlockWindowsUpdate];
			[self sendPaintMessage];
		
	END_TRY;
}

@end

