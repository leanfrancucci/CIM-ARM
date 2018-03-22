#include "JWorkOrderForm.h"
#include "util.h"
#include "JMessageDialog.h"
#include "MessageHandler.h"
#include "Audit.h"
#include "Event.h"
#include "JSystem.h"
#include "JInstaDropForm.h"
#include "SettingsExcepts.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)

@implementation  JWorkOrderForm


/**/
- (void) onCreateForm
{

	[super onCreateForm];
	
	// Label Numero de orden
	myLabelOrderNumber = [JLabel new];
	[myLabelOrderNumber setCaption: getResourceStringDef(RESID_NUMBER_WORDER, "Numero de Orden:")];
	[myLabelOrderNumber setAutoSize: FALSE];
	[myLabelOrderNumber setWidth: 20];
	[self addFormComponent: myLabelOrderNumber];
	
  [self addFormEol];

	myTextOrderNumber = [JText new];
	[myTextOrderNumber setWidth: 8];
	[myTextOrderNumber setHeight: 1];	
	[myTextOrderNumber setMaxLen: 8];
	[myTextOrderNumber setPasswordMode: FALSE];
	[myTextOrderNumber setNumericMode: TRUE];
	[self addFormComponent: myTextOrderNumber];  
}

/**/
- (char *) getCaption1
{
	return getResourceStringDef(RESID_BACK_KEY, "atras");
}

/**/
- (void) onMenu1ButtonClick
{
	myModalResult = JFormModalResult_CANCEL;
	[self closeForm];
}

/**/
- (char *) getCaption2
{
	return getResourceStringDef(RESID_ACCEPT, "aceptar");
}

/**/
- (void) onMenu2ButtonClick
{

  // valido que el numero no sea vacia
  if (strlen([myTextOrderNumber getText]) == 0)
    THROW(RESID_NULL_WORDER_NUMBER_MSG);

  // valido que el numero no supere los 40000000
  if ((atoi([myTextOrderNumber getText]) == 0) || (atoi([myTextOrderNumber getText]) > 40000000))
    THROW(RESID_INVALID_RANGE_WORDER_NUMBER_MSG);    
    
  // genero la auditoria con el numero de orden ingresado
  [Audit auditEventCurrentUser: EVENT_WORK_ORDER additional: [myTextOrderNumber getText] station: 0 logRemoteSystem: FALSE];

  [JMessageDialog askOKMessageFrom: self 
      withMessage: getResourceStringDef(RESID_INSERT_WORDER_OK, "Indicacion de orden de trabajo exitosa!")];
  
	myModalResult = JFormModalResult_OK;
	[self closeForm];
	
	
}

@end

