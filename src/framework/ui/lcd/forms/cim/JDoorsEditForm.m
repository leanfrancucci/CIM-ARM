#include "JDoorsEditForm.h"
#include "MessageHandler.h"
#include "JMessageDialog.h"
#include "Event.h"
#include "Audit.h"
#include "JExceptionForm.h"
#include "Door.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JDoorsEditForm

static char mySaveMsg[] = "Save ?";


/**/
- (void) onCreateForm
{
	[super onCreateForm];

	[self setCloseOnAccept: TRUE];
	[self setCloseOnCancel: TRUE];

	myLabelDoorName = [self addLabelFromResource: RESID_NAME default: "Nombre Puerta:"];
	myTextDoorName = [JText new];
	[myTextDoorName setWidth: 16];
	[self addFormComponent: myTextDoorName];

	[self addFormNewPage];

	myLabelSensorType = [self addLabelFromResource: RESID_Door_SENSOR_TYPE default: "Tipo sensor:"];
	myComboSensorType = [JCombo new];
	[myComboSensorType setWidth: 17];
	[myComboSensorType setHeight: 1];
	[myComboSensorType addString: getResourceStringDef(RESID_Door_SENSOR_TYPE_NONE, "Ninguno")];
	[myComboSensorType addString: getResourceStringDef(RESID_Door_SENSOR_TYPE_LOCKER, "Cerradura")];
	[myComboSensorType addString: getResourceStringDef(RESID_Door_SENSOR_TYPE_PLUNGER, "Plunger")];
	[myComboSensorType addString: getResourceStringDef(RESID_Door_SENSOR_TYPE_BOTH, "Ambos")];
	[myComboSensorType addString: getResourceStringDef(RESID_Door_SENSOR_TYPE_PLUNGER_EXT, "Plunger-Ext")];
	[myComboSensorType setSelectedIndex: 0];

	[self addFormComponent: myComboSensorType];

	[self setConfirmAcceptOperation: TRUE];

}

/**/
- (void) onModelToView: (id) anInstance
{
	[myComboSensorType setSelectedIndex: [anInstance getSensorType] - 1];
	[myTextDoorName setText: [anInstance getDoorName]];

}

/**/
- (void) onViewToModel: (id) anInstance
{
	[anInstance setSensorType: [myComboSensorType getSelectedIndex] + 1];
	[anInstance setDoorName: [myTextDoorName getText]];
	
}

/**/
- (void) onAcceptForm: (id) anInstance
{
	int i;
	JFORM processForm = NULL;

  TRY
    processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];
    
  	[anInstance applyChanges];
  
    [processForm closeProcessForm];
    [processForm free];
      	
  	[self closeForm];
  	
  CATCH
  
    [processForm closeProcessForm];
    [processForm free];
    RETHROW();
        
  END_TRY
}


/**/
- (void) onMenu2ButtonClick
{							
	[super onMenu2ButtonClick];
}
	
/**/
- (char *) getConfirmAcceptMessage: (char *) aMessage toSave: (id) anInstance
{
	return getResourceStringDef(RESID_SAVE_WITH_QUESTION_MARK, mySaveMsg);
}
@end

