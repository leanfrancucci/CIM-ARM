#ifndef  JSPLASH_FORM_H
#define  JSPLASH_FORM_H

#define  JSPLASH_FORM  id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JButton.h"
#include "JProgressBar.h"

/**
 *
 */
@interface  JSplashForm: JCustomForm
{
	JLABEL			labelMessage;
	JLABEL			labelMessage2;
	JPROGRESS_BAR	progressBar;
}


@end

#endif

