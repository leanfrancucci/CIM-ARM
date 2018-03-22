#include <assert.h>
#include "util.h"
#include "UserInterfaceDefs.h"
#include "JMessageDialog.h"
#include "MessageHandler.h"
#include "system/printer/all.h"
#include "JExceptionForm.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)


@implementation  JMessageDialog

static JMESSAGE_DIALOG		singleInstance = NULL;

/**
 * Devuelve la instancia que utilizan los metodos de clase para acceder al dialogo.
 */
+ getInstance
{
	if (singleInstance == NULL)
		singleInstance = [JMessageDialog createDialog: NULL];
		
	return singleInstance;
}

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

/**
 * Metodos protegidos
 */

/**/
- (int) getScreenDialogHeight
{
	return myHeight - 1;	
}		 

/**
 * Se llama al crear el dialogo para poder crear los controles adecuados.
 */
- (void) addDialogControls
{
	myLabelMenu1 = [JLabel new];	
	[myLabelMenu1 setAutoSize: FALSE];
	[myLabelMenu1 setWidth: myWidth / 3];		
	[myLabelMenu1 setTextAlign: UTIL_AlignLeft];
	[myLabelMenu1 setCaption: getResourceStringDef(RESID_MENU_1, "Menu 1")];
	[self addComponent: myLabelMenu1];

	[self  addBlanks: 1];
	
	myLabelMenuX = [JLabel new];
	[myLabelMenuX setAutoSize: FALSE];	
	[myLabelMenuX setWidth: myWidth / 3];		
	[myLabelMenuX setTextAlign: UTIL_AlignCenter];
	[myLabelMenuX setCaption: getResourceStringDef(RESID_MENU_X, "Menu X")];
	[self  addComponent: myLabelMenuX];
	
	[self  addBlanks: 1];
	
	myLabelMenu2 = [JLabel new];	
	[myLabelMenu2 setAutoSize: FALSE];
	[myLabelMenu2 setWidth: myWidth / 3];		
	[myLabelMenu2 setTextAlign: UTIL_AlignRight];
	[myLabelMenu2 setCaption: getResourceStringDef(RESID_MENU_2, "Menu 2")];	
	[self  addComponent: myLabelMenu2];
}
 
/**
 * Se llama al abrir el dialogo para poder configurar el caption de los labels.
 */
- (void) configDialogControls
{
	switch (myAskingMode) {
		 
		case JDialogMode_ASK_OK_MESSAGE:
							[myLabelMenu1 setCaption: ""];	
							[myLabelMenuX setCaption: ""];	
							[myLabelMenu2 setCaption: getResourceStringDef(RESID_OK_UPPER, "OK")];
							break;				 
		
		case JDialogMode_ASK_YES_NO_MESSAGE:
							[myLabelMenu1 setCaption: getResourceStringDef(RESID_NO_UPPER, "NO")];
							[myLabelMenuX setCaption: ""];
							[myLabelMenu2 setCaption: getResourceStringDef(RESID_YES_UPPER, "SI")];
							break;				
		
		case JDialogMode_ASK_YES_NO_CANCEL_MESSAGE:
							[myLabelMenu1 setCaption: getResourceStringDef(RESID_NO_UPPER, "NO")];
							[myLabelMenuX setCaption: getResourceStringDef(RESID_CANCEL_UPPER, "CANCEL.")];
							[myLabelMenu2 setCaption: getResourceStringDef(RESID_YES_UPPER, "SI")];
							break;				
		
		case JDialogMode_ASK_OK_CANCEL_MESSAGE:
							[myLabelMenu1 setCaption: getResourceStringDef(RESID_CANCEL_UPPER, "CANCEL.")];
							[myLabelMenuX setCaption: ""];
							[myLabelMenu2 setCaption: getResourceStringDef(RESID_OK_UPPER, "OK")];
							break;		
	}
}

- (void) paperOutNotification
{
	JDialogResult result;	
	result = [JExceptionForm showYesNoForm: getResourceStringDef(RESID_OUT_OF_PAPER, "Error en la impresion. Falta de papel. Reintentar?")];
	
	if (result == JDialogResult_YES) {
	
		[[PrinterSpooler getInstance] reprintLastJob];
		
	} else {
	
		[[PrinterSpooler getInstance] cancelLastJob];
		
	}
		
}


/**/
- (BOOL) doProcessMessage: (JEvent *) anEvent
{
	/**/
	if (anEvent->evtid == JEventQueueMessage_SHOW_ALARM) {
	//	doLog("JMessageDialog -> entrando al doProcessMessage\n");
		[JMessageDialog askOKMessageFrom: self withMessage: (char*)anEvent->evtParam1];
//		doLog("JMessageDialog -> saliendo del doProcessMessage\n");
		free((char*)anEvent->evtParam1);
		return TRUE;
	}

	return [super doProcessMessage: anEvent];
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
      result = [JExceptionForm showOkForm: "Es necesario un cierre Z. Las impresiones se han perdido."];                  
      
      if (result == JDialogResult_YES) 
        [[PrinterSpooler getInstance] cancelLastJob];
      
      break;                
      
    
    default:
      break;      
  }
	
		
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed
{
	
	if (!anIsPressed)
			return FALSE;
	
	/* La envia arriba a ver si la quieren procesar */
	if (![super doKeyPressed: aKey isKeyPressed: anIsPressed])
		switch (aKey) {

			case UserInterfaceDefs_KEY_MENU_X:
				[self doMenuXButtonClick];
				return TRUE;

			case UserInterfaceDefs_KEY_MENU_1:
				[self doMenu1ButtonClick];
				return TRUE;

			case UserInterfaceDefs_KEY_MENU_2:
				[self doMenu2ButtonClick];
				return TRUE;
		}

	return FALSE;
}


/**/
- (void) doMenu1ButtonClick
{
	if (myAskingMode == JDialogMode_ASK_YES_NO_MESSAGE ||
		  myAskingMode == JDialogMode_ASK_YES_NO_CANCEL_MESSAGE)		  
		[self doNoEvent];
					
	if (myAskingMode == JDialogMode_ASK_OK_CANCEL_MESSAGE) 
		[self doCancelEvent];
}

/**/
- (void) doMenuXButtonClick
{
	if (myAskingMode == JDialogMode_ASK_YES_NO_CANCEL_MESSAGE)
		[self doCancelEvent];
}


/**/
- (void) doMenu2ButtonClick
{
	if (myAskingMode == JDialogMode_ASK_YES_NO_MESSAGE ||
		  myAskingMode == JDialogMode_ASK_YES_NO_CANCEL_MESSAGE)
		[self doYesEvent];
	
	if (myAskingMode == JDialogMode_ASK_OK_MESSAGE ||
		  myAskingMode == JDialogMode_ASK_OK_CANCEL_MESSAGE)
		[self doOkEvent];
}

/**/ 
+ (JDialogResult) askOKMessageFrom: (JWINDOW) aParentWindow withMessage: (char *) aMessage
{
	return [[JMessageDialog getInstance] askOKMessageFrom: aParentWindow withMessage: aMessage];
}

/**/ 
+ (JDialogResult) askYesNoMessageFrom: (JWINDOW) aParentWindow withMessage: (char *) aMessage
{
	return [[JMessageDialog getInstance] askYesNoMessageFrom: aParentWindow withMessage: aMessage];
}

/**/ 
+ (JDialogResult) askYesNoCancelMessageFrom: (JWINDOW) aParentWindow withMessage: (char *) aMessage
{
	return [[JMessageDialog getInstance] askYesNoCancelMessageFrom: aParentWindow withMessage: aMessage];
}

/**/ 
+ (JDialogResult) askOkCancelMessageFrom: (JWINDOW) aParentWindow withMessage: (char *) aMessage
{	
	return [[JMessageDialog getInstance] askOkCancelMessageFrom: aParentWindow withMessage: aMessage];
}

/**/
+ (void) showExceptionDialogFrom: (JWINDOW) aParentWindow 
				 exceptionCode: (int) anExceptionCode
				 exceptionName: (char*) anExceptionName
{
	char myExceptionMessage[ JComponent_MAX_LEN + 1 ];
	char myExceptionDescription[ JComponent_MAX_LEN + 1 ];
	JWINDOW oldForm;
	JMESSAGE_DIALOG dialog;	
	
	TRY
		
		[[MessageHandler getInstance] processMessage: myExceptionDescription 
									 								 messageNumber: anExceptionCode];
																	 
		snprintf(myExceptionMessage, JComponent_MAX_LEN, myExceptionDescription);
	
	CATCH
		
		snprintf(myExceptionMessage, JComponent_MAX_LEN, "Exception: %d! %s", anExceptionCode, anExceptionName);
	
	END_TRY
	
	oldForm = [JWindow getActiveWindow];
	if (oldForm) [oldForm deactivateWindow];
	
//	[[InputKeyboardManager getInstance] setIgnoreKeyEvents: TRUE];	
	
	dialog = [JMessageDialog new];
	[dialog openWindowWithModalMode: FALSE];
	[dialog paintComponent];
	
	msleep(5000);
		
	//askOKMessageFrom: aParentWindow withMessage: myExceptionMessage];
	
//	[[InputKeyboardManager getInstance] setIgnoreKeyEvents: FALSE];	
	
	if (oldForm) [oldForm activateWindow];

}

@end

