#include "JAmountEditForm.h"
#include "AmountSettings.h"
#include "JMessageDialog.h"
#include "MessageHandler.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation  JAmountEditForm


/**/
- (void) onCreateForm
{
	[super onCreateForm];
	printd("JAmountEditForm:onCreateForm\n");


	/* Round Type */
	myLabelRoundType = [JLabel new];
	[myLabelRoundType setCaption: getResourceStringDef(RESID_ROUND_TYPE, "Tipo de redondeo:")];
	[self addFormComponent: myLabelRoundType];


	myComboRoundType = [JCombo new];
	[myComboRoundType addString: getResourceStringDef(RESID_NORMAL_ROUND, "Normal")]; 
	[myComboRoundType addString: getResourceStringDef(RESID_UP_ROUND, "Hacia arriba")];
	[myComboRoundType addString: getResourceStringDef(RESID_DOWN_ROUND, "Hacia abajo")];

	[self addFormComponent: myComboRoundType];

	[self addFormNewPage];
	
	// Items Round Decimal Qty 
	myLabelItemsRoundDecimalQty = [JLabel new];
	[myLabelItemsRoundDecimalQty setCaption: getResourceStringDef(RESID_ITEMS_DECIMAL, "Decimales items:")];	
	[self addFormComponent: myLabelItemsRoundDecimalQty];

  [self addFormEol];
  
	myTextItemsRoundDecimalQty = [JText new];
	[myTextItemsRoundDecimalQty setNumericMode: TRUE];
  [myTextItemsRoundDecimalQty setWidth: 1];
	
	[self addFormComponent: myTextItemsRoundDecimalQty];

	[self addFormNewPage];

	// Subtotal Round Decimal Qty 
	myLabelSubtotalRoundDecimalQty = [JLabel new];
	[myLabelSubtotalRoundDecimalQty setCaption: getResourceStringDef(RESID_SUBTOTAL_DECIMAL, "Decimales subtotal:")];	
	[self addFormComponent: myLabelSubtotalRoundDecimalQty];

  [self addFormEol];
  
	myTextSubtotalRoundDecimalQty = [JText new];
	[myTextSubtotalRoundDecimalQty setNumericMode: TRUE];
  [myTextSubtotalRoundDecimalQty setWidth: 1];
	
	[self addFormComponent: myTextSubtotalRoundDecimalQty];

	[self addFormNewPage];

	// Total Round Decimal Qty 
	myLabelTotalRoundDecimalQty = [JLabel new];
	[myLabelTotalRoundDecimalQty setCaption: getResourceStringDef(RESID_TOTAL_DECIMAL, "Decimales total:")];	
	[self addFormComponent: myLabelTotalRoundDecimalQty];

	[self addFormEol];
  
  myTextTotalRoundDecimalQty = [JText new];
	[myTextTotalRoundDecimalQty setNumericMode: TRUE];
  [myTextTotalRoundDecimalQty setWidth: 1];
	
	[self addFormComponent: myTextTotalRoundDecimalQty];

	[self addFormNewPage];

	// Tax Round Decimal Qty 
	myLabelTaxRoundDecimalQty = [JLabel new];
	[myLabelTaxRoundDecimalQty setCaption: getResourceStringDef(RESID_TAX_DECIMAL, "Decimales imp.:")];	
	[self addFormComponent: myLabelTaxRoundDecimalQty];

	[self addFormEol];
  
  myTextTaxRoundDecimalQty = [JText new];
	[myTextTaxRoundDecimalQty setNumericMode: TRUE];
  [myTextTaxRoundDecimalQty setWidth: 1];
	
	[self addFormComponent: myTextTaxRoundDecimalQty];

	[self setConfirmAcceptOperation: TRUE];
}

/**/
- (void) onCancelForm: (id) anInstance
{
	printd("JAmountEditForm:onAcceptForm\n");

	assert(anInstance != NULL);

	[anInstance restore];
}

/**/
- (void) onModelToView: (id) anInstance
{
	printd("JAmountEditForm:onModelToView\n");

	assert(anInstance != NULL);

	/* Round type */
	[myComboRoundType setSelectedIndex: [anInstance getRoundType] - 1];

	// Items round decimal qty 
	[myTextItemsRoundDecimalQty setLongValue: [anInstance getItemsRoundDecimalQty]];

	// Subtotal round decimal qty 
	[myTextSubtotalRoundDecimalQty setLongValue: [anInstance getSubtotalRoundDecimalQty]];

	// Total round decimal qty 
	[myTextTotalRoundDecimalQty setLongValue: [anInstance getTotalRoundDecimalQty]];

	// Tax round decimal qty 
	[myTextTaxRoundDecimalQty setLongValue: [anInstance getTaxRoundDecimalQty]];

}

/**/
- (void) onViewToModel: (id) anInstance
{
	printd("JAmountEditForm:onViewToModel\n");

	assert(anInstance != NULL);

	/* Round type */
	[anInstance setRoundType:  [myComboRoundType getSelectedIndex] + 1];

	// Items round decimal qty
	[anInstance setItemsRoundDecimalQty:  [myTextItemsRoundDecimalQty getLongValue]];

	// Subtotal round decimal qty 
	[anInstance setSubtotalRoundDecimalQty:  [myTextSubtotalRoundDecimalQty getLongValue]];

	// Total round decimal qty 
	[anInstance setTotalRoundDecimalQty:  [myTextTotalRoundDecimalQty getLongValue]];

	// Tax round decimal qty 
	[anInstance setTaxRoundDecimalQty:  [myTextTaxRoundDecimalQty getLongValue]];

}

/**/
- (void) onAcceptForm: (id) anInstance
{
	printd("JAmountEditForm:onAcceptForm\n");

	assert(anInstance != NULL);

	/* Graba el amount */
	[anInstance applyChanges];
	[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_RESTART_EQUIPMENT, "Para aplicar los cambios, reinicie el equipo.")];
	 	
}


@end

  
