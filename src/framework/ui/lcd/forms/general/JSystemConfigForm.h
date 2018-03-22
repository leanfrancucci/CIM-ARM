#ifndef  JSYSTEM_CONFIG_FORM_H
#define  JSYSTEM_CONFIG_FORM_H

#define  JSYSTEM_CONFIG_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JNumericText.h"
#include "JCombo.h"

/**
 *
 */
@interface  JSystemConfigForm: JEditForm
{
	JLABEL myLabelIP;
	JTEXT	myTextIP;

	JLABEL myLabelNetmask;
	JTEXT	myTextNetmask;

	JLABEL myLabelGateway;
	JTEXT	myTextGateway;

	JLABEL myLabelDHCP;
	JCOMBO	myComboDHCP;
	  		  
}


@end

#endif

