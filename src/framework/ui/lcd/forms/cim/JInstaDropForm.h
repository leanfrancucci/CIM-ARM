#ifndef  JINSTA_DROP_FORM_H
#define  JINSTA_DROP_FORM_H

#define  JINSTA_DROP_FORM  id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JDate.h"
#include "JTime.h"
#include "User.h"
#include "JGrid.h"


/**
 *	Pantalla de configuracion de teclas para Insta Drop.
 */
@interface  JInstaDropForm: JCustomForm
{
	JLABEL myLabelTitle;
	JLABEL myLabelMsg;
	JGRID  myGrid;
	BOOL   myIsApplicationForm;
}

/**/
- (void) setIsApplicationForm: (BOOL) aValue;

@end

#endif

