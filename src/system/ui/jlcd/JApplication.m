#include <assert.h>

#include "UserInterfaceExcepts.h"
#include "UserInterfaceDefs.h"
#include "JApplication.h"
#include "JDialog.h"
#include "JVirtualScreen.h"
#include "PrinterSpooler.h"
#include "lcdlib.h"

//#define printd(args...) doLog(args)
#define printd(args...)


/**
 *
 *
 */

@implementation  JApplication


/***
 * Metodos Publicos
 */


/**/
- (void) initComponent
{
 [super initComponent];
 
	myMainApplicationForm = NULL;
	
	myFormsList = [OrdCltn new];
	assert(myFormsList != NULL);

	myCanClose = FALSE;
	
}


/**/
- free
{	
	[myFormsList freeContents];	
	[myFormsList free];	
	
	return [super free];
}


/**/
- (void) startApplication
{
	[self onStartApplication];
	
	/* si en onStartApplication() no se muestra un formulario se muestra el primero de la lista */
	if (myActiveForm == NULL) {
    myActiveForm = [myFormsList at: 0];
 	  [self onActivateApplicationForm: myActiveForm previousActiveForm: myPreviousActiveForm];	
  }    
    
	THROW_NULL( myActiveForm );
}

/**/
- (void) stopApplication
{
	[self onStopApplication];
}

/**/
- (BOOL) doProcessMessage: (JEvent *) anEvent
{

	switch (anEvent->evtid) {
	
		/* cierra la aplicacion */	
		case JEventQueueMessage_CLOSE_APPLICATION:
								
						[self stopApplication];
						return FALSE;						
										
		/* Key Pressed Event */
		case JEventQueueMessage_KEY_PRESSED:

						/* Si la aplicacion puede procesar la tecla retorna TRUE.
							como esta la cosa la aplicacion nunca maneja la tecla.  */					
						if (![self processKey: anEvent->event.keyEvt.keyPressed 
																					isKeyPressed: anEvent->event.keyEvt.isPressed])
							break;
							
						return TRUE;

		/* Cambiar al formulario principal de la aplicacion */
		case JEventQueueMessage_ACTIVATE_MAIN_APPLICATION_FORM:
		
						[self activateMainApplicationForm];
						return TRUE;
	
		/* Cambiar el formulario activo al siguiente formulario */
		case JEventQueueMessage_ACTIVATE_NEXT_APPLICATION_FORM:
		
						[self activateNextApplicationForm];
						return TRUE;
		
    default:
						break;
	}
	
  
  if (myActiveForm != NULL)
		[myActiveForm doProcessMessage: anEvent];				
	
  return TRUE;
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed
{	
	return FALSE;	
}

/**/
- (void) addApplicationForm: (JFORM) aForm
{
	assert(aForm);
	[myFormsList add: aForm];	
	[aForm setOwner: self];
	[aForm setCanClose: FALSE];
}

/**/
- (JFORM) getActiveApplicationForm
{
	return myActiveForm;
} 

/**/
- (void) activateApplicationForm: (JFORM) aForm
{
	THROW_NULL( aForm );
	
	if (myActiveForm != NULL)
		[myActiveForm deactivateWindow];
	
	myPreviousActiveForm = myActiveForm;
	myActiveForm = aForm;

 	[self onActivateApplicationForm: myActiveForm previousActiveForm: myPreviousActiveForm];	
  [myActiveForm showForm];  
}

/**/
- (void) deactivateApplicationForm: (JFORM) aForm
{
	THROW_NULL( aForm );
	if (myActiveForm == aForm) {
		if (myActiveForm != NULL) 
			[myActiveForm deactivateWindow];
		[self activateNextApplicationForm];	
	}
}

/**/
- (void) setMainApplicationForm: (JFORM) aForm { myMainApplicationForm = aForm; }
- (JFORM) getMainApplicationForm { return myMainApplicationForm; }

/**/
- (void) activateMainApplicationForm
{
	if (myMainApplicationForm == NULL)
		return;
	
	if (myActiveForm != myMainApplicationForm)
		[self activateApplicationForm: myMainApplicationForm];		
}

/**/
- (void) activateNextApplicationForm
{
	int i;
	JFORM wichForm = NULL;

	/* Si sale del formulario main se queda en la vista en la que estaba antes de entrar al main */
	if (myActiveForm == myMainApplicationForm) {
		
		wichForm = myPreviousActiveForm;
		
	} else { /* Va a la siguiente vista */
	
		for (i = 0; i < [myFormsList size]; i++)
				if ([myFormsList at: i] == myActiveForm) 
					break;
			
			if (i >= [myFormsList size] - 1)
				wichForm = [myFormsList at: 0];
			else
				wichForm = [myFormsList at: i + 1];
	}
	
	THROW_NULL( wichForm );
	
  // Solo pinta en el caso en que el formulario que tenga que activar sea diferente al activo
  if ( myActiveForm != wichForm ) 
	 [self activateApplicationForm: wichForm];		
}

/**/
- (void) onStartApplication
{
}

/**/
- (void) onStopApplication
{
}	

/**/
- (void) onActivateApplicationForm: (JFORM) anActiveForm previousActiveForm: (JFORM) aPreviousForm
{
	anActiveForm = anActiveForm;
	aPreviousForm = aPreviousForm;
}

/**/
- (void) onActivateMainApplicationForm: aMainForm previousActiveForm: aPreviousForm
{
	aMainForm = aMainForm;
	aPreviousForm = aPreviousForm;
}

/**/
- (void) activateCurrentView
{
	THROW_NULL( myActiveForm );
	
  if ( myActiveForm == myMainApplicationForm ) 
    [self activateNextApplicationForm];    
  else {
    [self onActivateApplicationForm: myActiveForm previousActiveForm: myPreviousActiveForm];	
    [myActiveForm showForm];  
  }    
}

/**/
- (void) onDeactivateApplicationForm: (JFORM) anActiveForm previousActiveForm: (JFORM) aPreviousForm
{
}

/**/
- (void) deactivateCurrentView
{
	[self onDeactivateApplicationForm: myActiveForm previousActiveForm: myPreviousActiveForm];
  if ( myActiveForm ) [myActiveForm deactivateWindow];
} 
	
@end

