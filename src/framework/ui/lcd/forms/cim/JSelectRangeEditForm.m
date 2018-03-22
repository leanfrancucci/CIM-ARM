#include "UserInterfaceExcepts.h"
#include "JSelectRangeEditForm.h"
#include "SystemTime.h"
#include "JMessageDialog.h"
#include "JExceptionForm.h"
#include "cttypes.h"
#include "MessageHandler.h"
#include "Persistence.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation  JSelectRangeEditForm
static char myCaption2[] = "aceptar";

/**/
- (void) onCreateForm
{
  char buff[10];
  [super onCreateForm];

  // Desde numero
  myLabelFromRange = [JLabel new];
  strcpy(buff,getResourceStringDef(RESID_FROM_DATE_LABEL, "Desde:"));
  strcat(buff," ");
  [myLabelFromRange setCaption: buff];
  [self addFormComponent: myLabelFromRange];
    
	myTextFromRange = [JText new];
	[myTextFromRange setWidth: 6];
	[myTextFromRange setNumericMode: TRUE];
	[myTextFromRange setText: ""];
	[self addFormComponent: myTextFromRange];
    
  [self addFormEol];
  
  // Hasta numero
  myLabelToRange = [JLabel new];
  strcpy(buff,getResourceStringDef(RESID_TO_DATE_LABEL, "Hasta:"));
  strcat(buff," ");  
  [myLabelToRange setCaption: buff];
  [self addFormComponent: myLabelToRange];
  
	myTextToRange = [JText new];
	[myTextToRange setWidth: 6];
	[myTextToRange setNumericMode: TRUE];
	[myTextToRange setText: ""];
	[self addFormComponent: myTextToRange];  
  
}

/**/
- (void) onOpenForm
{
  char buff[10];
  
  sprintf(buff, "%ld", from);
  
  [myTextFromRange setText: buff];
  [myTextToRange setText: buff];
}

/**/
- (unsigned long) getFromRange
{
  return from;
}

/**/
- (unsigned long) getToRange
{
  return to;
}


/**/
- (void) setFromRange: (unsigned long) aValue
{
  from = aValue;
}

/**/
- (void) setToRange: (unsigned long) aValue
{
  to = aValue;
}

/**/
- (void) onMenu1ButtonClick
{
	printd("JSelectRangeEditForm:onMenu1ButtonClick\n");

  from = 0;
  to = 0;
  
  [self closeForm];
}

/**/
- (void) onMenu2ButtonClick
{
	printd("JSelectRangeEditForm:onMenu2ButtonClick\n");

  // valido los valores
  if ( strlen([myTextFromRange getText]) == 0 )
    THROW(UI_NULLED_EX);
    
  if ( strlen([myTextToRange getText]) == 0 )
    THROW(UI_NULLED_EX);
    
  from = atoi([myTextFromRange getText]);
	if (from == 0) from = 1;
  to = atoi([myTextToRange getText]);
	if (to == 0) to = 1;

  if ( from > to )
    THROW(UI_INVALID_RANGE);
	
	if ( (to - from + 1) > 100 )
		THROW(UI_BIG_RANGE);

  [self closeForm];
}


/**/
- (char*) getCaption2
{
  return getResourceStringDef(RESID_ACCEPT, myCaption2);
}


@end

