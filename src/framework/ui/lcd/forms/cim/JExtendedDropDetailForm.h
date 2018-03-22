#ifndef  JEXTENDED_DROP_DETAIL_FORM_H
#define  JEXTENDED_DROP_DETAIL_FORM_H

#define  JEXTENDED_DROP_DETAIL_FORM  id

#include "JCustomForm.h"

#include "JLabel.h"
#include "User.h"
#include "JGrid.h"
#include "Deposit.h"
#include "CimCash.h"
#include "system/os/all.h"

typedef enum {
	ExtendedDropView_AMOUNT
 ,ExtendedDropView_QTY
} ExtendedDropView;

/**
 *	Pantalla de visualizacion de detalle de extended drop (por validador)
 */
@interface  JExtendedDropDetailForm: JCustomForm
{
	JLABEL myLabelTitle;
	JGRID  myGrid;
	DEPOSIT myDeposit;
	CIM_CASH myCimCash;
	int myTotalDecimals;
	USER myUser;
	ExtendedDropView myCurrentView;
	OTIMER myTimer;
}

/**/
- (void) setDeposit: (DEPOSIT) aDeposit;

@end

#endif

