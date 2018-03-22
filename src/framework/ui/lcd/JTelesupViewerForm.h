#ifndef  JTELESUP_VIEWER_FORM_H
#define  JTELESUP_VIEWER_FORM_H

#define  JTELESUP_VIEWER_FORM id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JButton.h"
#include "JProgressBar.h"
#include "JTime.h"
#include "system/os/all.h"

/**
 *
 */
@interface  JTelesupViewerForm: JForm
{
	JLABEL      labelTitle;
	JLABEL			labelMessage;
	JLABEL			labelBytes;
	JTIME				timeElapsed;
	JPROGRESS_BAR	progressBar;
	OTIMER			timer;
	int					elapsed;
}

- (void) updateDisplay: (char*) aMessage;
- (void) updateTransfered: (long) aBytes totalBytes: (long) aTotalBytes;
- (void) updateTitle: (char*) aTitle;
- (void) start;
- (void) stop;

@end

#endif

