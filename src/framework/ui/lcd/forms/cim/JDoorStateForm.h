#ifndef  JDOOR_STATE_FORM_H
#define  JDOOR_STATE_FORM_H

#define  JDOOR_STATE_FORM  id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JDate.h"
#include "JTime.h"
#include "system/db/all.h"
#include "ExtractionWorkflow.h"


/** 
 	*	Define cual es el workflow actual (para el caso de tener una puerta dentro de otra)
	*/
typedef enum {
	ExtWorkflowType_NORMAL
 ,ExtWorkflowType_INNER
} ExtWorkflowType;

/**
 *	
 */
@interface  JDoorStateForm: JCustomForm
{
	JLABEL myLabelDoorName;
	JLABEL myLabelMessage;
	JLABEL myLabelTimeLeft;
	OTIMER myUpdateTimer;
	BOOL myIsClosingForm;
	EXTRACTION_WORKFLOW myExtractionWorkflow;
	OMUTEX myMutex;
	BOOL myOpenDoorForCommercialChange;
	BOOL myBagVerification;
	ExtWorkflowType myLastExtWorkflow;
	char myCurrentDoorStr[20];
}

/**/
- (void) setExtractionWorkflow: (EXTRACTION_WORKFLOW) aValue;

/**/
- (void) setOpenDoorForCommercialChange: (BOOL) aValue;

/**/
- (void) setBagVerification: (BOOL) aValue;

@end

#endif

