#ifndef  JUPDATE_FIRMWARE_FORM_H
#define  JUPDATE_FIRMWARE_FORM_H

#define  JUPDATE_FIRMWARE_FORM  id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JButton.h"
#include "JProgressBar.h"
#include "BillAcceptor.h"

/**
 *
 */
@interface  JUpdateFirmwareForm: JForm
{
	JLABEL myLabelTitle;
	JLABEL myLabel2Title;
	JLABEL myLabelAcceptorName;
	JPROGRESS_BAR	myProgressBar;
	int myCurrentProgress;
	BILL_ACCEPTOR myBillAcceptor;
}

/**/
- (void) setMessage: (char *) aMessage;

/**/
- (void) setMessage2: (char *) aMessage;

/**/
- (void) setMessage3: (char *) aMessage;

/**/
- (void) setBillAcceptor: (BILL_ACCEPTOR) aBillAccceptor;

/**/
- (void) setProgress: (int) aProgress;

@end

#endif

