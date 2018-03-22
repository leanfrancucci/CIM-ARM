#ifndef LCD_TELESUP_VIEWER_H
#define LCD_TELESUP_VIEWER_H

#define LCD_TELESUP_VIEWER id

#include <Object.h>
#include "ctapp.h"
#include "TelesupViewer.h"
#include "JTelesupViewerForm.h"

/**
 *	doc template
 */
@interface LCDTelesupViewer : TelesupViewer
{
	JTELESUP_VIEWER_FORM telesupForm;
	JFORM oldForm;

}


@end

#endif
