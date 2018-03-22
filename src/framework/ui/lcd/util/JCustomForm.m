#include <assert.h>
#include "UserInterfaceDefs.h"
#include "JCustomForm.h"
#include "JMessageDialog.h"

#include "JSystem.h"
#include "JText.h"
#include "JList.h"
#include "JCombo.h"
#include "JGrid.h"
#include "JCheckBox.h"
#include "JButton.h"
#include "JMainMenu.h"
#include "MessageHandler.h"
#include "keypadlib.h"
#include "system/printer/all.h"

#include "JExceptionForm.h"
#include "CimManager.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JCustomForm


static char myBackMessage[] 					= "atras";
static char myCloseMessage[] 					= "cerrar";
static char myDeleteMessage[] 				= "borrar";
static char mySelectMessage[] 				= "selecc";			
static char myButtonPressedMessage[] 	= "selec.";
static char myUnCheckMessage[] 	= "desmar";
static char myCheckMessage[] 	= "marcar";
                

/**/
- (void) initComponent
{
	[super initComponent];
}
	
/**/
- free
{
	return [super free];
}


/**/
- (void) doCreateForm
{
	[super doCreateForm];
	
	/*
	 *	Hace [super addComponent: myXXXX] porque el addComponent() en JCustomform
	 *	esta reimplementado para que el componente lo agregue al JScrollPanel.
	 */
	myScrollPanel = [JScrollPanel new];		
	[myScrollPanel setWidth: myWidth]; 
	[myScrollPanel setHeight: myHeight - 1]; 
	[self addComponent: myScrollPanel];
	
	myStatusBar = [JCustomStatusBar new];		
	[myStatusBar setWidth: myWidth];
	[myStatusBar setHeight: 1];			
	[self addComponent: myStatusBar];	
}

/**/
- (void) advancePaper
{
//	[[Spooler getInstance] advancePaper];
//	[[PrinterSpooler getInstance] addPrintingJob: ADVANCE_PAPER_PRT copiesQty: 0 ignorePaperOut: TRUE tree: NULL];
	[[PrinterSpooler getInstance] addPrintingJob: ADVANCE_PAPER_PRT copiesQty: 0 ignorePaperOut: TRUE tree: NULL additional: 0];
	
//	int i;
//	if ( ![[Printer getInstance] tryPrinting]) return;
	
	/*
	[[Printer getInstance] startAdvancePaper];
	
	// Seteo el teclado en modo RAW para poder recibir
	// el KEY_RELEASED de la tecla.
	kp_set_raw_mode();
	
	doLog(0,"PONER IMPRESORA EN LINEA\n");
	doLog(0,"AVANCE DE PAPEL\n");

	// Espero hasta que presione una tecla e imprimo
	// lineas mientras tanto
	while (!kp_kbhit())
	{
		msleep(5);
	}

	doLog(0,"Presiono una tecla\n");
		
	[[Printer getInstance] stopAdvancePaper];

	// Lo configuro en modo XLATE
	kp_set_xlate_mode();
	kp_set_navigation_mode();
	*/
}


/**
 * Reimplementa los metodos de JContainer para delegarlos directamente
 * al componente JSCrollPanel
 */
 
/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed
{
	if (!anIsPressed)
			return FALSE;

	/* La envia la tecla al scroll panel para que la maneje a ver si la quiere procesar */
	if ([myScrollPanel processKey: aKey isKeyPressed: anIsPressed]) {
		
		if  (aKey == JComponent_TAB || aKey == JComponent_SHIFT_TAB || aKey == UserInterfaceDefs_KEY_MENU_1 ||
				 aKey == UserInterfaceDefs_KEY_MENU_X || aKey == JComponent_CTRL_TAB || aKey == UserInterfaceDefs_KEY_MENU_2)
			[self doChangeStatusBarCaptions];
		
		/* Esto lo hago porque si no el cursor se redibuja en cualquier lado */
		[myScrollPanel drawCursor];
		return TRUE;
	}

	/* Si es alguna de las teclas especiales entonces las procesa */	
	switch (aKey) {	

			case UserInterfaceDefs_KEY_MENU_1:
				[self doMenu1ButtonClick];
				return TRUE;

			case UserInterfaceDefs_KEY_MENU_X:
				[self doMenuXButtonClick];
				return TRUE;

			case UserInterfaceDefs_KEY_MENU_2:
				[self doMenu2ButtonClick];
				return TRUE;

			case JComponent_CTRL_TAB:				
				[self doViewButtonClick];
				return TRUE;								

			case UserInterfaceDefs_KEY_RIGHT:				
				[self advancePaper];
				return TRUE;
				
		}

	return FALSE;
}

/**/
- (void) addFormComponent: (JCOMPONENT) aComponent
{
	assert(myScrollPanel);		
	[myScrollPanel addComponent: aComponent];
}

/**/
- (int) getFormComponentCount
{
	assert(myScrollPanel  != NULL);
	return [myScrollPanel getComponentCount];
}

/**/
- (JCOMPONENT) getFormComponentAt: (int) anIndex
{
	assert(myScrollPanel  != NULL);
	return [myScrollPanel getComponentAt: anIndex];
}

		
/**/
- (void) addFormBlanks: (int) aQty
{ 
	assert(myScrollPanel);		
	[myScrollPanel addBlanks: aQty];
}

/**/
- (void) addFormEol
{
	assert(myScrollPanel);		
	[myScrollPanel addEol];
}

/**/
- (void) addFormNewPage
{
	assert(myScrollPanel);		
	[myScrollPanel addNewPage];	
}

/**/
- (int) getFormCurrentPage
{
	assert(myScrollPanel);		
	return [myScrollPanel getCurrentPage];		
}

/**/
- (void) focusFormComponent: (JCOMPONENT) aComponent
{
  assert(myScrollPanel);
	[myScrollPanel focusComponent: aComponent];
	[self onChangedFocusedComponent];
}

/**/
- (JCOMPONENT) getFormFocusedComponent
{
	assert(myScrollPanel);		
	return [myScrollPanel getFocusedComponent];	
}


/**/
- (void) focusFormFirstComponent
{
	assert(myScrollPanel);		
	[self focusFirstComponent];
	[myScrollPanel focusFirstComponent];
}

/**/
- (void) focusFormNextComponent
{
	//doLog(0,"focusFormNextComponent\n");

  assert(myScrollPanel);		
	[myScrollPanel focusNextComponent];
}


/**/
- (void) focusFormPreviousComponent
{
	assert(myScrollPanel);		
	[myScrollPanel focusPreviousComponent];
}

/**/
- (void) focusFormFirstComponentInCurrentPage
{
	assert(myScrollPanel);		
	[myScrollPanel focusFirstComponentInCurrentPage];
	
}
 
/**/
- (void) showDefaultExceptionDialogWithExCode: (int) anExceptionCode
{	
		char myExceptionMessage[ JComponent_MAX_LEN + 1 ];
		JWINDOW oldForm;

		//doLog(0,"JCustomForm -> showDefaultExceptionDialogWithExCode, self = %s\n", [self name]);

		oldForm = [JWindow getActiveWindow];
		if (oldForm) {
			//doLog(0,"Old form class Name = %s\n", [oldForm name]);

			[oldForm deactivateWindow];
		}

    TRY

			ex_printfmt();      
      snprintf(myExceptionMessage, JComponent_MAX_LEN, [[MessageHandler getInstance] processMessage: myBufferCustomForm messageNumber: anExceptionCode]);
    
    CATCH
		  snprintf(myExceptionMessage, JComponent_MAX_LEN, "Exception: %d!", anExceptionCode);

    END_TRY
    
    
    [JMessageDialog askOKMessageFrom: self withMessage: myExceptionMessage];
	
		if (oldForm) [oldForm activateWindow];

}

/**
 * Meotodos especificos de la clase
 */

 
/**/
- (void) doMenuXButtonClick
{
	[self onMenuXButtonClick];
}

/**/
- (void) doMenu1ButtonClick
{
	[self onMenu1ButtonClick];	
}


/**/
- (void) doMenu2ButtonClick
{
	[self onMenu2ButtonClick];
}

/**/
- (void) doViewButtonClick
{
	[self onViewButtonClick];
}


/**
 * Metodos protegidos
 */

  
/**/
- (void) onCreateForm
{
	[super onCreateForm];
}

/**/
- (void) onChangedFocusedComponent
{
	[self doChangeStatusBarCaptions];
}

/**/
- (void) onMenu1ButtonClick
{
	[self closeForm];
}

/**/
- (void) onMenuXButtonClick
{
}

/**/
- (void) onMenu2ButtonClick
{	
}

/**/
- (void) onViewButtonClick
{
	if (!myModalMode)
		[[JSystem getInstance] sendActivateNextApplicationFormMessage];
}


/**/
- (void) doChangeStatusBarCaptions
{		
	[myStatusBar setCaption1: [self getCaption1]];
	[myStatusBar setCaptionX: [self getCaptionX]];
	[myStatusBar setCaption2: [self getCaption2]];
}	

/**/
- (char *) getCaption1
{
	JCOMPONENT component = [self getFormFocusedComponent];
		
	/* JMainMenu */
	if (component != NULL &&
			[component isKindOf: (id) [JMainMenu class]] && 
			[component getCurrentMenuLevel] > 1)
		return getResourceStringDef(RESID_BACK_KEY, myBackMessage);
	
	if (myCanClose)
		return getResourceStringDef(RESID_CLOSE_KEY, myCloseMessage);
		
	return NULL;
}


/**/
- (char *) getCaptionX
{	
	JCOMPONENT component = [self getFormFocusedComponent];
	
	/**/
	if (component != NULL) {
			
		/* JText */
		if ([component isKindOf: (id) [JText class]] && ![component isReadOnly])						
				return getResourceStringDef(RESID_DELETE_KEY, myDeleteMessage);

    if ([component isKindOf: (id) [JCheckBox class]] && [component isChecked] && ![component isReadOnly])
        return getResourceStringDef(RESID_UNCHECK_KEY, myUnCheckMessage);

    if ([component isKindOf: (id) [JCheckBox class]] && ![component isChecked] && ![component isReadOnly])
        return getResourceStringDef(RESID_CHECK_KEY, myCheckMessage);
                
		/* JCombo, JList*/
		else if ((/*[component isKindOf: (id) [JCombo class]] || */
					    [component isKindOf: (id) [JList  class]] ||
							[component isKindOf: (id) [JGrid  class]])  &&
							![component isReadOnly] && [component hasOnSelectAction])
					return getResourceStringDef(RESID_SELECT_KEY, mySelectMessage);
		
		/* JButton */
		else if ([component isKindOf: (id) [JButton class]])
						return myButtonPressedMessage;
		
	}

	return NULL;		
}

/**/
- (char *) getCaption2
{	
	JCOMPONENT component = [self getFormFocusedComponent];
	
	/* JMainMenu */
	if (component != NULL && [component isKindOf: (id) [JMainMenu class]])				
		return getResourceStringDef(RESID_SELECT_KEY, mySelectMessage);
	
	return NULL;	
}

/**/
- (void) printerStateNotification: (int) aPrinterState
{
	JDialogResult result;

  switch ( aPrinterState ) {
  
    case PrinterState_PAPER_OUT:
      result = [JExceptionForm showYesNoForm: getResourceStringDef(RESID_OUT_OF_PAPER, "Error en la impresion. Falta de papel. Reintentar?")];
      
      if (result == JDialogResult_YES) 
        [[PrinterSpooler getInstance] reprintLastJob];
      else 
        [[PrinterSpooler getInstance] cancelLastJob];
      
      break;
      
    case PrinterState_OUT_OF_LINE:      
      result = [JExceptionForm showYesNoForm: "Impresora fuera de linea. Reintentar?"];
      
      if (result == JDialogResult_YES) 
        [[PrinterSpooler getInstance] reprintLastJob];
      else 
        [[PrinterSpooler getInstance] cancelLastJob];
    
      break;
      
    case PrinterState_PRINTER_INTERNAL_FATAL_ERROR:
      result = [JExceptionForm showYesNoForm: "Error interno en la impresion. Reintentar?"];
      
      if (result == JDialogResult_YES) 
        [[PrinterSpooler getInstance] reprintLastJob];
      else 
        [[PrinterSpooler getInstance] cancelLastJob];
      
      break;
       
    case PrinterState_PRINTER_FATAL_ERROR:
      result = [JExceptionForm showOkForm: "Error fatal en la controladora fiscal."];
      
      if (result == JDialogResult_YES) 
        [[PrinterSpooler getInstance] cancelLastJob];
      
      break;

    case PrinterState_PRINTER_NOT_RESPONDING_BERIGUEL:
      result = [JExceptionForm showOkForm: "La impresora no responde."];                  
      
      if (result == JDialogResult_YES) 
        [[PrinterSpooler getInstance] cancelLastJob];
      
      break;                
      
    case PrinterState_PRINTER_NEEDS_CLOSE_Z:      
      result = [JExceptionForm showOkForm: "Es necesario emitir un cierre Z."];                  
      
      if (result == JDialogResult_YES) 
        [[PrinterSpooler getInstance] cancelLastJob];
      
      break;                
      
    
    default:
      break;      
  }
	
  
}


/**/
- (void) acceptorSerialNumberChangeNotification: (int) anAcceptorId
{
	char buffer[50];

	//doLog(0,"**************************************\n");
	//doLog(0,"acceptorSerialNumberChangeNotification\n");

	sprintf(buffer, "%s%s%s", getResourceStringDef(RESID_DEVICE_CHANGE, "Cambio en el dispositivo:"), " ", [[[[CimManager getInstance] getCim] getAcceptorSettingsById: anAcceptorId] getAcceptorName]);

	[JExceptionForm showOkForm: buffer];

}


/**/
- (JLABEL) addLabel: (char *) aText
{
  JLABEL label = [JLabel new];

	if (strlen(aText) > JComponent_MAX_WIDTH) {
		[label setHeight: 2];
		[label setWidth: 20];
		[label setWordWrap: TRUE];
	}

	[label setCaption: aText];

	[self addFormComponent: label];
	[self addFormEol];
	
	return label;
}

/**/
- (BOOL) doProcessMessage: (JEvent *) anEvent
{
	/**/
	if (anEvent->evtid == JEventQueueMessage_SHOW_ALARM) {
		//doLog(0,"JCustomForm -> entrando al doProcessMessage\n");
		[JMessageDialog askOKMessageFrom: self withMessage: (char*)anEvent->evtParam1];
		//doLog(0,"JCustomForm -> saliendo del doProcessMessage\n");
		free((char*)anEvent->evtParam1);
		return FALSE;
	}

	return [super doProcessMessage: anEvent];
}

/**/
- (JCOMBO) createNoYesCombo
{
	JCOMBO jCombo = [JCombo new];

	[jCombo addString: getResourceStringDef(RESID_NO, "No")]; 
	[jCombo addString: getResourceStringDef(RESID_YES, "Si")]; 

	[self addFormComponent: jCombo];

	return jCombo;
}

/**/
- (JLABEL) addLabelFromResource: (int) aResource
{
	return [self addLabel: getResourceString(aResource)];
}

/**/
- (JLABEL) addLabelFromResource: (int) aResource default: (char *) aDefault
{
	return [self addLabel: getResourceStringDef(aResource, aDefault)];
}

@end

