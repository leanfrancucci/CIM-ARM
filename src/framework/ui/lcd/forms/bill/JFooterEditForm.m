#include "JFooterEditForm.h"
#include "BillSettings.h"
#include "MessageHandler.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation  JFooterEditForm

/**/
- (void) onCreateForm
{
	[super onCreateForm];
	
	/* Footer 1 */
	myLabelFooter1 = [JLabel new];
	[myLabelFooter1 setCaption: getResourceStringDef(RESID_FOOTER1, "Pie 1:")];	
	[self addFormComponent: myLabelFooter1];

	myTextFooter1 = [JText new];
	[myTextFooter1 setWidth: 20];
	[myTextFooter1 setHeight: 2];
	[myTextFooter1 setMaxLen: 23];
	[self addFormComponent: myTextFooter1];

	[self addFormNewPage];
	
	/* Footer 2 */
	myLabelFooter2 = [JLabel new];
	[myLabelFooter2 setCaption: getResourceStringDef(RESID_FOOTER2, "Pie 2:")];	
	[self addFormComponent: myLabelFooter2];

	myTextFooter2 = [JText new];
	[myTextFooter2 setWidth: 20];
	[myTextFooter2 setHeight: 2];
  [myTextFooter2 setMaxLen: 23];
	[self addFormComponent: myTextFooter2];

	[self addFormNewPage];
	/* Footer 3 */
	myLabelFooter3 = [JLabel new];
	[myLabelFooter3 setCaption: getResourceStringDef(RESID_FOOTER3, "Pie 3:")];	
	[self addFormComponent: myLabelFooter3];

	myTextFooter3 = [JText new];
	[myTextFooter3 setWidth: 20];
	[myTextFooter3 setHeight: 2];
  [myTextFooter3 setMaxLen: 23];
	[self addFormComponent: myTextFooter3];

	[self setConfirmAcceptOperation: TRUE];
}

/**/
- (void) onCancelForm: (id) anInstance
{
	assert(anInstance != NULL);
	[anInstance restore];

}

/**/
- (void) onModelToView: (id) anInstance
{
	assert(anInstance != NULL);

	/* Footer 1 */
	[myTextFooter1 setText: [anInstance getFooter1]];

	/* Footer 2 */
	[myTextFooter2 setText: [anInstance getFooter2]];

	/* Footer 3 */
	[myTextFooter3 setText: [anInstance getFooter3]];

}

/**/
- (void) onViewToModel: (id) anInstance
{
	assert(anInstance != NULL);

	/* Footer 1*/
	[anInstance setFooter1:  trim([myTextFooter1 getText])];

	/* Footer 2*/
	[anInstance setFooter2:  trim([myTextFooter2 getText])];

	/* Footer 3*/
	[anInstance setFooter3:  trim([myTextFooter3 getText])];

}

/**/
- (void) onAcceptForm: (id) anInstance
{
	assert(anInstance != NULL);

	/* Graba el footer */
	[anInstance applyChanges];
}

@end

