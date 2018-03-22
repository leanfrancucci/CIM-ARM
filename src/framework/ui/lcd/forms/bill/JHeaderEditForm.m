#include "JHeaderEditForm.h"
#include "BillSettings.h"
#include "MessageHandler.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)

@implementation  JHeaderEditForm

/**/
- (void) onCreateForm
{

	[super onCreateForm];
	
	/* Header 1 */
	myLabelHeader1 = [JLabel new];
	[myLabelHeader1 setCaption: getResourceStringDef(RESID_HEADER1, "Encabezado 1:")];	
	[self addFormComponent: myLabelHeader1];

	myTextHeader1 = [JText new];
	[myTextHeader1 setWidth: 20];
	[myTextHeader1 setHeight: 2];	
	[myTextHeader1 setMaxLen: 23];
	[self addFormComponent: myTextHeader1];

	[self addFormNewPage];
	
	/* Header 2 */
	myLabelHeader2 = [JLabel new];
	[myLabelHeader2 setCaption: getResourceStringDef(RESID_HEADER2, "Encabezado 2:")];	
	[self addFormComponent: myLabelHeader2];

	myTextHeader2 = [JText new];
	[myTextHeader2 setWidth: 20];
	[myTextHeader2 setHeight: 2];	
	[myTextHeader2 setMaxLen: 23];
	[self addFormComponent: myTextHeader2];

	[self addFormNewPage];

	/* Header 3 */
	myLabelHeader3 = [JLabel new];
	[myLabelHeader3 setCaption: getResourceStringDef(RESID_HEADER3, "Encabezado 3:")];	
	[self addFormComponent: myLabelHeader3];

	myTextHeader3 = [JText new];
	[myTextHeader3 setWidth: 20];
	[myTextHeader3 setHeight: 2];	
	[myTextHeader3 setMaxLen: 23];
	[self addFormComponent: myTextHeader3];

	[self addFormNewPage];

	/* Header 4 */
	myLabelHeader4 = [JLabel new];
	[myLabelHeader4 setCaption: getResourceStringDef(RESID_HEADER4, "Encabezado 4:")];	
	[self addFormComponent: myLabelHeader4];

	myTextHeader4 = [JText new];
	[myTextHeader4 setWidth: 20];
	[myTextHeader4 setHeight: 2];	
	[myTextHeader4 setMaxLen: 23];
	[self addFormComponent: myTextHeader4];

	[self addFormNewPage];

	/* Header 5 */
	myLabelHeader5 = [JLabel new];
	[myLabelHeader5 setCaption: getResourceStringDef(RESID_HEADER5, "Encabezado 5:")];	
	[self addFormComponent: myLabelHeader5];

	myTextHeader5 = [JText new];
	[myTextHeader5 setWidth: 20];
	[myTextHeader5 setHeight: 2];	
	[myTextHeader5 setMaxLen: 23];
	[self addFormComponent: myTextHeader5];

	[self addFormNewPage];

	/* Header 6 */
	myLabelHeader6 = [JLabel new];
	[myLabelHeader6 setCaption: getResourceStringDef(RESID_HEADER6, "Encabezado 6:")];	

	[self addFormComponent: myLabelHeader6];

	myTextHeader6 = [JText new];
	[myTextHeader6 setWidth: 20];
	[myTextHeader6 setHeight: 2];	
	[myTextHeader6 setMaxLen: 23];
	[self addFormComponent: myTextHeader6];

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

	/* Header 1 */	
	[myTextHeader1 setText: [anInstance getHeader1]];
	
	/* Header 2 */	
	[myTextHeader2 setText: [anInstance getHeader2]];

	/* Header 3 */	
	[myTextHeader3 setText: [anInstance getHeader3]];

	/* Header 4 */	
	[myTextHeader4 setText: [anInstance getHeader4]];

	/* Header 5 */	
	[myTextHeader5 setText: [anInstance getHeader5]];

	/* Header 6 */	
	[myTextHeader6 setText: [anInstance getHeader6]];

}

/**/
- (void) onViewToModel: (id) anInstance
{
	assert(anInstance != NULL);

	/* Header 1*/
	[anInstance setHeader1:  trim([myTextHeader1 getText])];

	/* Header 2*/
	[anInstance setHeader2:  trim([myTextHeader2 getText])];

	/* Header 3*/
	[anInstance setHeader3:  trim([myTextHeader3 getText])];

	/* Header 4*/
	[anInstance setHeader4:  trim([myTextHeader4 getText])];

	/* Header 5*/
	[anInstance setHeader5:  trim([myTextHeader5 getText])];

	/* Header 6*/
	[anInstance setHeader6:  trim([myTextHeader6 getText])];
}

/**/
- (void) onAcceptForm: (id) anInstance
{
	assert(anInstance != NULL);

	/* Graba el header */
	[anInstance applyChanges];
}

@end

