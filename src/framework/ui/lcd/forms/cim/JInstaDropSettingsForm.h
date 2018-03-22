#ifndef  JINSTA_DROP_SETTINGS_FORM_H
#define  JINSTA_DROP_SETTINGS_FORM_H

#define  JINSTA_DROP_SETTINGS_FORM  id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JDate.h"
#include "JTime.h"
#include "User.h"
#include "JGrid.h"


/**
 *	Pantalla de configuracion de teclas para Insta Drop.
 */
@interface  JInstaDropSettingsForm: JCustomForm
{
	JLABEL myLabelTitle;
	JGRID  myGrid;
	USER myUser;
}


@end

#endif

