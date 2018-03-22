#include "JGeneralEditForm.h"
#include "BillSettings.h"
#include "JMessageDialog.h"
#include "PrintingSettings.h"
#include "AmountSettings.h"
#include "TelesupScheduler.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation  JGeneralEditForm


/**/
- (void) onCreateForm
{
	[super onCreateForm];
	printd("JGeneralEditForm:onCreateForm\n");


	/* Tax discrimination */

  myLabelTaxDiscrimination = [JLabel new];
  [myLabelTaxDiscrimination setCaption: "Discrimina imp.:"];	
  [self addFormComponent: myLabelTaxDiscrimination];

  myComboTaxDiscrimination = [JCombo new];
  [myComboTaxDiscrimination addString: "No"]; 
  [myComboTaxDiscrimination addString: "Si"]; 

  [self addFormComponent: myComboTaxDiscrimination];

  [self addFormNewPage];

  
	/* Ticket type */
	myLabelTicketType= [JLabel new];
	[myLabelTicketType setCaption: "Tipo de ticket:"];	
	[self addFormComponent: myLabelTicketType];

	myComboTicketType = [JCombo new];
	[myComboTicketType addString: "Unitario"]; 
	[myComboTicketType addString: "Totalizador"]; 
	[self addFormComponent: myComboTicketType];
  
  [self addFormNewPage];
  
	/* Apertura del cajon de dinero */
	myLabelOpenCashDrawer= [JLabel new];
	[myLabelOpenCashDrawer setCaption: "Abre cajon dinero:"];	
	[self addFormComponent: myLabelOpenCashDrawer];

	myComboOpenCashDrawer = [JCombo new];
	[myComboOpenCashDrawer addString: "No"]; 
	[myComboOpenCashDrawer addString: "Si"]; 
	[self addFormComponent: myComboOpenCashDrawer];

  [self addFormNewPage];

	/* Monto minimo */
	[self addLabel: "Monto minimo:"];
	myNumericTextMinAmount = [JNumericText new];
  [myNumericTextMinAmount setWidth: 10];
  [myNumericTextMinAmount setDecimalDigits: [[AmountSettings getInstance] getTotalRoundDecimalQty]];
  [myNumericTextMinAmount setMoneyValue: 0];
	[self addFormComponent: myNumericTextMinAmount];
  [self addFormNewPage];

	/* Desc. del Identificador tributario */
	myLabelIdentifierDescription= [JLabel new];
	[myLabelIdentifierDescription setCaption: "Desc. identificador tributario:"];	
	[myLabelIdentifierDescription setWidth: 20];
	[myLabelIdentifierDescription setHeight: 2];
	[myLabelIdentifierDescription setWordWrap: TRUE];
	[self addFormComponent: myLabelIdentifierDescription];

	myTextIdentifierDescription = [JText new];
	[myTextIdentifierDescription setWidth: 20];
	[myTextIdentifierDescription setHeight: 1];	
	[myTextIdentifierDescription setMaxLen: 20];
	[self addFormComponent: myTextIdentifierDescription];

  [self setConfirmAcceptOperation: TRUE];
}

/**/
- (void) onCancelForm: (id) anInstance
{
	printd("JGeneralEditForm:onAcceptForm\n");

	[anInstance restore];

}

/**/
- (void) onModelToView: (id) anInstance
{
	
	printd("JGeneralEditForm:onModelToView\n");
	
	assert(anInstance != NULL);


	/* Tax discrimination */
  [myComboTaxDiscrimination setSelectedIndex: [anInstance getTaxDiscrimination]];

  /* Tipo de ticket */
  [myComboTicketType setSelectedIndex: [anInstance getTicketType] - 1];
  
  /* Apertura de cajon de dinero */
  [myComboOpenCashDrawer setSelectedIndex: [anInstance getOpenCashDrawer]];

	/* Monto minimo */	
	[myNumericTextMinAmount setMoneyValue: [anInstance getMinAmount]];

	/* Descripcion del Identificador tributario */
	[myTextIdentifierDescription setText: [anInstance getIdentifierDescription]];

	
}

/**/
- (void) onViewToModel: (id) anInstance
{
	printd("JGeneralEditForm:onViewToModel\n");

	assert(anInstance != NULL);

	/* Tax discrimination */
  [anInstance setTaxDiscrimination:  [myComboTaxDiscrimination getSelectedIndex]];
   
  /* Tipo de ticket */
	[anInstance setTicketType:  [myComboTicketType getSelectedIndex] + 1];  
  
  /* Apertura de cajon de dinero */
  [anInstance setOpenCashDrawer: [myComboOpenCashDrawer getSelectedIndex]];

	/* Monto minimo */	
	[anInstance setMinAmount: [myNumericTextMinAmount getMoneyValue]];

	/* Descripcion del Identificador tributario */
	[anInstance setIdentifierDescription: [myTextIdentifierDescription getText]];


}

/**/
- (void) onAcceptForm: (id) anInstance
{
	printd("JGeneralEditForm:onAcceptForm\n");

	assert(anInstance != NULL);

	/* Graba la configuracion general del ticket */
	[anInstance applyChanges];

  [JMessageDialog askOKMessageFrom: self withMessage: "Para aplicar los cambios, reinicie el equipo."];            
}


@end

