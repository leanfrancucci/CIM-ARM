#ifndef  JTELESUPERVISION_EDIT_FORM_H
#define  JTELESUPERVISION_EDIT_FORM_H

#define  JTELESUPERVISION_EDIT_FORM id

#include "JEditForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JCombo.h"
#include "JDate.h"
#include "JTime.h"


/**
 *
 */
@interface  JTelesupervisionEditForm: JEditForm
{
	JCOMBO myComboTelesupType;
	JLABEL myLabelSystemId;
	JTEXT	myTextSystemId;
  JLABEL myLabelDescription;
  JTEXT myTextDescription;
  JLABEL myLabelFrequency;
  JTEXT myTextFrequency;
	JTEXT	myTextUserName;
	JTEXT	myTextPassword;
	JLABEL myLabelISPPhoneNumber;
	JTEXT	myTextISPPhoneNumber;
	JLABEL myLabelISPUserName;
	JTEXT	myTextISPUserName;
	JLABEL myLabelISPPassword;
	JTEXT	myTextISPPassword;
	JLABEL myLabelAttemptsQty;
	JTEXT myTextAttemptsQty;
	JLABEL myLabelTimeBetweenAttempts;
	JTEXT myTextATimeBetweenAttempts;
	JLABEL myLabelConnectBy;
	JCOMBO myComboConnectBy;
	JLABEL myLabelDomainSup;
	JTEXT myTextDomainSup;
	JLABEL myLabelIP;
	JTEXT myTextIP;
	JLABEL myLabelTCPPort;
	JTEXT myTextTCPPort;
	JLABEL myLabelSpeed;
	JCOMBO myComboSpeed;
	JLABEL myLabelFromHour;
	JTEXT  myTextFromHour;
	JLABEL myLabelToHour;
	JTEXT  myTextToHour;
	JLABEL myLabelActive;
	JCOMBO myComboActive;
	JLABEL myLabelRemoteUserName;
	JTEXT	myTextRemoteUserName;
	JLABEL myLabelRemotePassword;
	JTEXT	myTextRemotePassword;
	JLABEL myLabelRemoteSistemId;
	JTEXT	myTextRemoteSistemId;
	JLABEL myLabelComPort;
	JCOMBO myComboComPort;
	JLABEL myLabelConnectionType;
	JCOMBO myComboConnectionType;
	JLABEL myLabelNextTelDate;
	JDATE myDateNextTelDate;
	JLABEL myLabelNextTelTime;
	JTIME myTimeNextTelTime;
	JLABEL myLabelNextSecTelDate;
	JDATE myDateNextSecTelDate;
	JLABEL myLabelNextSecTelTime;
	JTIME myTimeNextSecTelTime;
	JLABEL myLabelFrame;
	JTEXT myTextFrame;
	JLABEL myLabelDomain;
	JTEXT	myTextDomain;
	JLABEL myLabelInformDeposits;
	JCOMBO myComboInformDeposits;
	JLABEL myLabelInformExtractions;
	JCOMBO myComboInformExtractions;
	JLABEL myLabelInformAlarms;
	JCOMBO myComboInformAlarms;
	JLABEL myLabelInformZClose;
	JCOMBO myComboInformZClose;

	int myOldConnectionType;

}


@end

#endif

