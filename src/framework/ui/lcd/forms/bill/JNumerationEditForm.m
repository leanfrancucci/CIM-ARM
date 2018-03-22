#include "JNumerationEditForm.h"
#include "BillSettings.h"
#include "JMessageDialog.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation  JNumerationEditForm


/**/
- (void) onCreateForm
{
	[super onCreateForm];
	printd("JNumerationEditForm:onCreateForm\n");


	/* Prefijo */
	myLabelPrefix = [JLabel new];
	[myLabelPrefix setCaption: "Prefijo: "];	
	[self addFormComponent: myLabelPrefix];

  [self addFormEol];
  
	myTextPrefix = [JText new];
	[myTextPrefix setWidth: 8];
	[myTextPrefix setMaxLen: 8];

	[self addFormComponent: myTextPrefix];

  [self addFormNewPage];
  
	/* Numero inicial */
	myLabelInitialNumber = [JLabel new];
	[myLabelInitialNumber setCaption: "Num. inicial:"];	
	[self addFormComponent: myLabelInitialNumber];
  
  [self addFormEol];

	myTextInitialNumber = [JText new];
	[myTextInitialNumber setWidth: 8];
	[myTextInitialNumber setMaxLen: 8];
  [myTextInitialNumber setNumericMode: TRUE];   
	[self addFormComponent: myTextInitialNumber];

 	[self addFormNewPage];
  
	/* DigitsQty */
	[self addLabel: "Cant.digitos ticket:"];	

	myTextDigitsQty = [JText new];
	[myTextDigitsQty setWidth: 1];
	[myTextDigitsQty setMaxLen: 1];
  [myTextDigitsQty setNumericMode: TRUE];   
	[self addFormComponent: myTextDigitsQty];

	[self setConfirmAcceptOperation: TRUE];
}

/**/
- (void) onCancelForm: (id) anInstance
{
	printd("JNumerationEditForm:onAcceptForm\n");

	assert(anInstance != NULL);

	[anInstance restore];

}

/**/
- (void) onModelToView: (id) anInstance
{
	printd("JNumerationEditForm:onModelToView\n");

	assert(anInstance != NULL);

	/* Prefijo */
	[myTextPrefix setText: [anInstance getPrefix]];

	/* Initial Number */
	[myTextInitialNumber setLongValue: [anInstance getInitialNumber]];

	/* DigitsQty */
	[myTextDigitsQty setLongValue: [anInstance getDigitsQty]];

}

/**/
- (void) onViewToModel: (id) anInstance
{
	printd("JNumerationEditForm:onViewToModel\n");

	assert(anInstance != NULL);

	/* Prefix*/
	[anInstance setPrefix:  [myTextPrefix getText]];

	/* Footer 2*/
	[anInstance setInitialNumber:  [myTextInitialNumber getLongValue]];

	/* DigitsQty */
	[anInstance setDigitsQty: [myTextDigitsQty getLongValue]];

}

/**/
- (void) onAcceptForm: (id) anInstance
{
	printd("JNumerationEditForm:onAcceptForm\n");

	assert(anInstance != NULL);

	/* Graba la numeracion */
	[anInstance applyChanges];
  
  [JMessageDialog askOKMessageFrom: self withMessage: "Para aplicar los cambios, reinicie el equipo."];          
}


@end

