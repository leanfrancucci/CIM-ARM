#ifndef  JPRINTING_EDIT_FORM_H
#define  JPRINTING_EDIT_FORM_H

#define  JPRINTING_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JCombo.h"
#include "JNumericText.h"
#include "JText.h"

/**
 *
 */
@interface  JPrintingEditForm: JEditForm
{
  JLABEL myLabelPrinterType;
  JCOMBO myComboPrinterType;
  
  JLABEL myLabelCOMPort;
  JCOMBO myComboCOMPort;

  JLABEL myLabelLineQtyBetweenTickets;
  JTEXT myTextLineQtyBetweenTickets;

	int myLastPrinter;
	int myLastCOM;
	int myLastQtyLines;
  
	//JLABEL myLabelPrintingOption;
	//JCOMBO	myComboPrintingOption;
  
	//JLABEL myLabelCopies;
	//JCOMBO myComboCopies;

  //JLABEL myLabelPrintZeroTickets;
  //JCOMBO myComboPrintZeroTickets;
  
  //JLABEL myLabelPrinterCode;
  //JTEXT myTextPrinterCode;
}

@end

#endif

