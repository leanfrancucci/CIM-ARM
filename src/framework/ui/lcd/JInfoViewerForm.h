#ifndef  JINFO_VIEWER_FORM_H
#define  JINFO_VIEWER_FORM_H

#define  JINFO_VIEWER_FORM id

#include "JCustomForm.h"

#include "JLabel.h"

/**
 *
 */
@interface  JInfoViewerForm: JCustomForm
{
	JLABEL			labelMessage;
}

/**
 *	Setea el caption del formulario.
 */
- (void) setCaption: (char*) aCaption;

@end

#endif

