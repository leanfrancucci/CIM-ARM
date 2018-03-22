#include "JPrintingEditForm.h"
#include "PrintingSettings.h"
#include "BillSettings.h"
#include "JMessageDialog.h"
#include "ResourceStringDefs.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation  JPrintingEditForm


/**/
- (void) onCreateForm
{
	[super onCreateForm];
	printd("JPrintingEditForm:onCreateForm\n");

  // Tipo de impresora
  myLabelPrinterType = [JLabel new];
  [myLabelPrinterType setCaption: getResourceStringDef(RESID_PRINTER, "Impresora:")];
  [self addFormComponent: myLabelPrinterType];
  
  myComboPrinterType = [JCombo new];
	[myComboPrinterType addString: getResourceStringDef(RESID_INTERNAL_PRINTER, "Interna")];
	[myComboPrinterType addString: getResourceStringDef(RESID_EXTERNAL_PRINTER, "Externa")];
	[myComboPrinterType setOnSelectAction: self 	action: "printer_onSelect"];
  [self addFormComponent: myComboPrinterType];
  
  [self addFormNewPage];
  
  // Puerto impresora
  myLabelCOMPort = [JLabel new];
  [myLabelCOMPort setCaption: getResourceStringDef(RESID_PRINTER_COM_PORT, "COM Impresora:")];
  [self addFormComponent: myLabelCOMPort];
  
  [self addFormEol];
  
  myComboCOMPort = [JCombo new];
	[myComboCOMPort addString: "COM 1"];
	[myComboCOMPort addString: "COM 2"];
  [self addFormComponent: myComboCOMPort];

  [self addFormNewPage];
  
  // Cantidad de lineas de avance
  myLabelLineQtyBetweenTickets = [JLabel new];
  [myLabelLineQtyBetweenTickets setCaption: getResourceStringDef(RESID_PRINTER_LINES_QTY, "Cant Lineas avance:")];
  [self addFormComponent: myLabelLineQtyBetweenTickets];
  
  [self addFormEol];

  myTextLineQtyBetweenTickets = [JText new];
  [myTextLineQtyBetweenTickets setWidth: 2];
  [myTextLineQtyBetweenTickets setNumericMode: TRUE];
  
  [self addFormComponent: myTextLineQtyBetweenTickets];  

  /*[self addFormNewPage];
  
	// Option 
  myLabelPrintingOption = [JLabel new];
	[myLabelPrintingOption setCaption: "Opcion Impresion:"];	
	[self addFormComponent: myLabelPrintingOption];

	myComboPrintingOption = [JCombo new];
	[myComboPrintingOption addString: "Imprimir"]; 
	[myComboPrintingOption addString: "No imprimir"];
	[myComboPrintingOption addString: "Efectuar pregunta"];

	[self addFormComponent: myComboPrintingOption];

	[self addFormNewPage];
  
	// Cantidad de copias
	myLabelCopies = [JLabel new];
	[myLabelCopies setCaption: "Cantidad copias:"];
	[self addFormComponent: myLabelCopies];

	myComboCopies = [JCombo new];
	[myComboCopies addString: "Solo original"];
	[myComboCopies addString: "Duplicado"];
	[myComboCopies addString: "Triplicado"];
	
	[self addFormComponent: myComboCopies];
	
  [self addFormNewPage];

	// Impresion de tickets con valor cero
	myLabelPrintZeroTickets = [JLabel new];
	[myLabelPrintZeroTickets setCaption: "Imprime tick. cero:"];	
	[self addFormComponent: myLabelPrintZeroTickets];
	
  myComboPrintZeroTickets = [JCombo new];
	[myComboPrintZeroTickets addString: "No"]; 
	[myComboPrintZeroTickets addString: "Si"]; 
	[self addFormComponent: myComboPrintZeroTickets];
  
  [self addFormNewPage];
  
  // Codigo de impresion
  myLabelPrinterCode = [JLabel new];
  [myLabelPrinterCode setCaption: "Codigo impresora:"];
  [self addFormComponent: myLabelPrinterCode];
  
  myTextPrinterCode = [JText new];
  [myTextPrinterCode setWidth: 10];
  [self addFormComponent:myTextPrinterCode];
	*/

  [self setConfirmAcceptOperation: TRUE];
}

/**/
- (void) printer_onSelect
{
	[myLabelCOMPort setVisible: FALSE];
	[myComboCOMPort setVisible: FALSE];

	[myLabelLineQtyBetweenTickets setVisible: FALSE];
	[myTextLineQtyBetweenTickets setVisible: FALSE];

	// se muestra el combo de COM solo para la impresora externa
	if ([myComboPrinterType getSelectedIndex] == 1) {
		[myLabelCOMPort setVisible: TRUE];
		[myComboCOMPort setVisible: TRUE];

		[myLabelLineQtyBetweenTickets setVisible: TRUE];
		[myTextLineQtyBetweenTickets setVisible: TRUE];
	}

	[self paintComponent];
}

/**/
- (void) onCancelForm: (id) anInstance
{
	printd("JPrintingEditForm:onCancelForm\n");

	assert(anInstance != NULL);

	[anInstance restore];

	[self focusFormFirstComponent];

}

/**/
- (void) onModelToView: (id) anInstance
{
  printd("JPrintingEditForm:onModelToView\n");
  
	assert(anInstance != NULL);
  
  /* Tipo de impresora*/
	[myComboPrinterType setSelectedIndex: [anInstance getPrinterType] - 1];
  
  /* Puerto impresora */
  [myComboCOMPort setSelectedIndex: [anInstance getPrinterCOMPort] - 1];

  // Cantidad de lineas de avance
  [myTextLineQtyBetweenTickets setLongValue: [anInstance getLinesQtyBetweenTickets]];

	myLastPrinter = [anInstance getPrinterType];
	myLastCOM = [anInstance getPrinterCOMPort];
	myLastQtyLines = [anInstance getLinesQtyBetweenTickets];

	[self printer_onSelect];

	// Opcion de impresion
	/*[myComboPrintingOption setSelectedIndex: [anInstance getPrintTickets] - 1];

  // Cantidad de copias
	[myComboCopies setSelectedIndex: [anInstance getCopiesQty] - 1];
  
  // Impresion de tickets con valor cero
  [myComboPrintZeroTickets setSelectedIndex: [anInstance getPrintZeroTickets]]; 
  
  // Codigo de impresora
  [myTextPrinterCode setText: [anInstance getPrinterCode]];*/
}

/**/
- (void) onViewToModel: (id) anInstance
{
	printd("JNumerationEditForm:onViewToModel\n");

	assert(anInstance != NULL);

  /* Tipo de impresora */
	[anInstance setPrinterType: [myComboPrinterType getSelectedIndex] + 1];

	// solo actualizo los valores de puerto y lineas de avance cuando es externa
	if ([myComboPrinterType getSelectedIndex] == 1) {
		// Puerto impresora
		[anInstance setPrinterCOMPort: [myComboCOMPort getSelectedIndex] + 1];
  	// Cantida de lineas de avance
  	[anInstance setLinesQtyBetweenTickets: [myTextLineQtyBetweenTickets getLongValue]];
	}

	// Opcion de impresion
	/*[anInstance setPrintTickets:  [myComboPrintingOption getSelectedIndex] + 1];

  // Cantidad de copias
	[anInstance setCopiesQty:  [myComboCopies getSelectedIndex] + 1];
  
  // Cantida de lineas de avance
  [anInstance setLinesQtyBetweenTickets: [myTextLineQtyBetweenTickets getLongValue]];
  
  // Impresion de tickets con valor cero
	[anInstance setPrintZeroTickets: [myComboPrintZeroTickets getSelectedIndex]];
  
  // Codigo de impresora
  [anInstance setPrinterCode: [myTextPrinterCode getText]];*/
}

/**/
- (void) onAcceptForm: (id) anInstance
{
	BOOL change = FALSE;

	printd("JNumerationEditForm:onAcceptForm\n");

	assert(anInstance != NULL);

	if (myLastPrinter != [anInstance getPrinterType])
		change = TRUE;
	else {
		if ( (myLastCOM != [anInstance getPrinterCOMPort]) || (myLastQtyLines != [anInstance getLinesQtyBetweenTickets]) )
			change = TRUE;
	}

	if (change) {
		/* Graba la impresion */
		[anInstance applyChanges];

  	[JMessageDialog askOKMessageFrom: self withMessage: getResourceStringDef(RESID_RESTART_EQUIPMENT, "Para aplicar los cambios, reinicie el equipo.")];
	}
}


@end

  
