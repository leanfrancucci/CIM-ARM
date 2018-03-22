#include "Audit.h"
#include "Persistence.h"
#include "ctapp.h"
#include "system/util/all.h"
#include "UserManager.h"
#include "MessageHandler.h"
#include "TelesupervisionManager.h"
#include "TelesupScheduler.h"
#include "EventManager.h"
#include "Acceptor.h"
#include "AuditDAO.h"
#include "CommercialStateMgr.h"
#include "CimBackup.h"

@implementation Audit

static BOOL myChangeLogActivated = TRUE; 


/**/
- (void) setAuditId: (int) anAuditId { myAuditId = anAuditId; };
- (void) setEventId: (int) aEventId { myEventId = aEventId; };
//- (void) setSystemType: (int) aSystemType { mySystemType = aSystemType; }
- (void) setAuditDate: (datetime_t) aDate { myDate = aDate; };
- (void) setUserId: (int) aUserId { myUserId = aUserId; };
- (void) setStation: (int) aStation { myStation = aStation; };

/**/
- (void) setAdditional: (char *) anAdditional
{
	strncpy2(myAdditional, anAdditional, AUDIT_ADDITIONAL_SIZE);
};

/**/
- (int) getAuditId { return myAuditId; }
- (int) getEventId { return myEventId; };
- (int) getSystemType { return mySystemType; }
- (datetime_t) getAuditDate { return myDate; };
- (char *) getAdditional { return myAdditional; };
- (int) getUserId { return myUserId; };
- (int) getStation { return myStation; };

/**/
- (unsigned long) saveAudit
{
  // Sino tiene fecha/hora le pongo la fecha/hora actual
  if (myDate == 0) myDate = [SystemTime getLocalTime];
	[[[Persistence getInstance] getAuditDAO] store: self];
  return myAuditId;
}

/**/
+ new 
{
  return [[super new] initialize];
}

/**/
- initialize
{
  myChangeLog = NULL;
  myDate = 0;
	myAlwaysLog = FALSE;
  return self;
}

/**/
- free
{
  if (myChangeLog) {
    [myChangeLog freePointers];
    [myChangeLog free];
  }

  return [super free];
}

/**/
- initAudit: (USER) aUser eventId: (int) anEventId additional: (char*) anAdditional station: (int) aStation logRemoteSystem: (BOOL) logRemoteSystem
{
  myUserId = 0;

  if (aUser) myUserId = [aUser getUserId];

	myAlwaysLog = FALSE;
  myEventId = anEventId;
  strncpy2(myAdditional, anAdditional, AUDIT_ADDITIONAL_SIZE);
  myStation = aStation;

	mySystemType = SystemType_CIM;

	if (logRemoteSystem) {
		if ([[Acceptor getInstance] isTelesupRunning]) mySystemType = SystemType_CMP;
		if ([[TelesupScheduler getInstance] inTelesup]) mySystemType = SystemType_PIMS;
	}

  return self;
}

/**/
- initAuditWithCurrentUser: (int) anEventId additional: (char*) anAdditional station: (int) aStation logRemoteSystem: (BOOL) logRemoteSystem
{
	USER user = [[UserManager getInstance] getUserLoggedIn];
  return [self initAudit: user eventId: anEventId additional: anAdditional station: aStation logRemoteSystem: logRemoteSystem];
}

/**/
- (COLLECTION) getChangeLog
{
  return myChangeLog;
}

/**/
- (void) addLog: (int) aResourceId oldValue: (char *) anOldValue newValue: (char *) aNewValue oldReference: (long) anOldReference newReference: (long) aNewReference
{
  ChangeLog *auditChange;

  if (myChangeLog == NULL) myChangeLog = [Collection new];

  auditChange = malloc(sizeof(ChangeLog));
  auditChange->field = aResourceId;
  stringcpy(auditChange->oldValue, anOldValue);
  stringcpy(auditChange->newValue, aNewValue);
	auditChange->oldReference = anOldReference;
	auditChange->newReference = aNewReference;

  [myChangeLog add: auditChange]; 
}

/* S T R I N G */
- (BOOL) logChangeAsString: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (char *) anOldValue newValue: (char *) aNewValue 
{
	return [self logChangeAsString: aLogAlways resourceId: aResourceId oldValue: anOldValue newValue: aNewValue oldReference: 0 newReference: 0];
}

- (BOOL) logChangeAsString: (int) aResourceId oldValue: (char *) anOldValue newValue: (char *) aNewValue
{
  return [self logChangeAsString: FALSE resourceId: aResourceId oldValue: anOldValue newValue: aNewValue];
}

/**/
- (BOOL) logChangeAsString: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (char *) anOldValue newValue: (char *) aNewValue oldReference: (long) anOldReference newReference: (long) aNewReference
{
  if (!myChangeLogActivated) return FALSE;
  if (!myAlwaysLog && !aLogAlways && strcmp(anOldValue, aNewValue) == 0) return FALSE;
  [self addLog: aResourceId oldValue: anOldValue newValue: aNewValue oldReference: anOldReference newReference: aNewReference];
  return TRUE;
}


/* R E S O U R C E  S T R I N G */
- (BOOL) logChangeAsResourceString: (BOOL) aLogAlways resourceId: (int) aResourceId resourceStringBase: (int) aResourceStringBase oldValue: (int) anOldValueResId newValue: (int) aNewValueResId 
{
	return [self logChangeAsResourceString: aLogAlways resourceId: aResourceId resourceStringBase: aResourceStringBase oldValue: anOldValueResId newValue: aNewValueResId oldReference: 0 newReference: 0];
}

/**/
- (BOOL) logChangeAsResourceString: (int) aResourceId resourceStringBase: (int) aResourceStringBase oldValue: (int) anOldValueResId newValue: (int) aNewValueResId
{
  return [self logChangeAsResourceString: FALSE resourceId: aResourceId resourceStringBase: aResourceStringBase oldValue: anOldValueResId newValue: aNewValueResId];
}

/**/
- (BOOL) logChangeAsResourceString: (BOOL) aLogAlways resourceId: (int) aResourceId resourceStringBase: (int) aResourceStringBase oldValue: (int) anOldValueResId newValue: (int) aNewValueResId oldReference: (long) anOldReference newReference: (long) aNewReference
{
  char oldValueStr[50], newValueStr[50];
  
  if (!myChangeLogActivated) return FALSE;
  if (!myAlwaysLog && !aLogAlways && anOldValueResId == aNewValueResId) return FALSE;

  if (anOldValueResId != 0)
    stringcpy(oldValueStr, getResourceString(aResourceStringBase + anOldValueResId));
  else
    stringcpy(oldValueStr, "");

  if (aNewValueResId != 0)
    stringcpy(newValueStr, getResourceString(aResourceStringBase + aNewValueResId));
  else
    stringcpy(newValueStr, "");

  [self addLog: aResourceId oldValue: oldValueStr newValue: newValueStr oldReference: anOldReference newReference: aNewReference];
  return TRUE;

}

/**/
- (BOOL) logChangeAsPassword: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (char *) anOldValue newValue: (char *) aNewValue 
{
	return [self logChangeAsPassword: aLogAlways resourceId: aResourceId oldValue: anOldValue newValue: aNewValue oldReference: 0 newReference: 0];

}

/**/
- (BOOL) logChangeAsPassword: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (char *) anOldValue newValue: (char *) aNewValue oldReference: (long) anOldReference newReference: (long) aNewReference
{
  if (!myChangeLogActivated) return FALSE;

  if (!myAlwaysLog && !aLogAlways && strcmp(anOldValue, aNewValue) == 0) return FALSE;
  [self addLog: aResourceId oldValue: "" newValue: "********" oldReference: anOldReference newReference: aNewReference];
  return TRUE;
}

/* B O O L E A N */
- (BOOL) logChangeAsBoolean: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (int) anOldValue newValue: (int) aNewValue 
{
	return [self logChangeAsBoolean: aLogAlways resourceId: aResourceId oldValue: anOldValue newValue: aNewValue oldReference: 
0 newReference: 0];
}

/**/
- (BOOL) logChangeAsBoolean: (int) aResourceId oldValue: (int) anOldValue newValue: (int) aNewValue 
{
  return [self logChangeAsBoolean: FALSE resourceId: aResourceId oldValue: anOldValue newValue: aNewValue];
}

/**/
- (BOOL) logChangeAsBoolean: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (int) anOldValue newValue: (int) aNewValue oldReference: (long) anOldReference newReference: (long) aNewReference
{
  char oldValueStr[50], newValueStr[50];

  if (!myChangeLogActivated) return FALSE;
  
	if (!myAlwaysLog && !aLogAlways && anOldValue == aNewValue) return FALSE;
  sprintf(oldValueStr, "%s", anOldValue ? getResourceStringDef(RESID_YES, "Si") : getResourceStringDef(RESID_NO, "No"));
  sprintf(newValueStr, "%s", aNewValue ? getResourceStringDef(RESID_YES, "Si") : getResourceStringDef(RESID_NO, "No"));

  [self addLog: aResourceId oldValue: oldValueStr newValue: newValueStr oldReference: anOldReference newReference: aNewReference];

  return TRUE;
}

/* I N T E G E R */
- (BOOL) logChangeAsInteger: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (int) anOldValue newValue: (int) aNewValue 
{
	return [self logChangeAsInteger: aLogAlways resourceId: aResourceId oldValue: anOldValue newValue: aNewValue oldReference: 0 newReference: 0];
}

/**/
- (BOOL) logChangeAsInteger: (int) aResourceId oldValue: (int) anOldValue newValue: (int) aNewValue 
{
  return [self logChangeAsInteger: FALSE resourceId: aResourceId oldValue: anOldValue newValue: aNewValue];
}

/**/
- (BOOL) logChangeAsInteger: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (int) anOldValue newValue: (int) aNewValue oldReference: (long) anOldReference newReference: (long) aNewReference
{
  char oldValueStr[50], newValueStr[50];

  if (!myChangeLogActivated) return FALSE;
  if (!myAlwaysLog && !aLogAlways && anOldValue == aNewValue) return FALSE;
  sprintf(oldValueStr, "%d", anOldValue);
  sprintf(newValueStr, "%d", aNewValue);

  [self addLog: aResourceId oldValue: oldValueStr newValue: newValueStr oldReference: anOldReference newReference: aNewReference];

  return TRUE;
}

/* M O N E Y */
- (BOOL) logChangeAsMoney: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (money_t) anOldValue newValue: (money_t) aNewValue
{
	return [self logChangeAsMoney: aLogAlways resourceId: aResourceId oldValue: anOldValue newValue: aNewValue oldReference: 0 newReference: 0];

}

/**/
- (BOOL) logChangeAsMoney: (int) aResourceId oldValue: (money_t) anOldValue newValue: (money_t) aNewValue
{
	return [self logChangeAsMoney: FALSE resourceId: aResourceId oldValue: anOldValue newValue: aNewValue];
}

/**/
- (BOOL) logChangeAsMoney: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (money_t) anOldValue newValue: (money_t) aNewValue oldReference: (long) anOldReference newReference: (long) aNewReference
{
  char oldValueStr[50], newValueStr[50];

  if (!myChangeLogActivated) return FALSE;
  if (!myAlwaysLog && !aLogAlways && anOldValue == aNewValue) return FALSE;
  formatMoney(oldValueStr, "", anOldValue, 6, 50);
  formatMoney(newValueStr, "", aNewValue, 6, 50);

  [self addLog: aResourceId oldValue: oldValueStr newValue: newValueStr oldReference: anOldReference newReference: aNewReference];

  return TRUE;
}

/* D A T E  T I M E */
- (BOOL) logChangeAsDateTime: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (datetime_t) anOldValue newValue: (datetime_t) aNewValue 
{
	return [self logChangeAsDateTime: aLogAlways resourceId: aResourceId oldValue: anOldValue newValue: aNewValue oldReference: 0 newReference: 0];
}

/**/
- (BOOL) logChangeAsDateTime: (int) aResourceId oldValue: (datetime_t) anOldValue newValue: (datetime_t) aNewValue 
{
  return [self logChangeAsDateTime: FALSE resourceId: aResourceId oldValue: anOldValue newValue: aNewValue oldReference: 0 newReference: 0];
}

/**/
- (BOOL) logChangeAsDateTime: (BOOL) aLogAlways resourceId: (int) aResourceId oldValue: (datetime_t) anOldValue newValue: (datetime_t) aNewValue oldReference: (long) anOldReference newReference: (long) aNewReference
{
  char oldValueStr[50], newValueStr[50];

  if (!myChangeLogActivated) return FALSE;
  if (!myAlwaysLog && !aLogAlways && anOldValue == aNewValue) return FALSE;
  datetimeToISO8106(oldValueStr, anOldValue);
  datetimeToISO8106(newValueStr, aNewValue);
  
  [self addLog: aResourceId oldValue: oldValueStr newValue: newValueStr oldReference: anOldReference newReference: aNewReference];

  return TRUE;  
}

/**/
- (BOOL) logChangeAsMoney: (int) aResourceId oldValue: (money_t) anOldValue newValue: (money_t) aNewValue oldReference: (long) anOldReference newReference: (long) aNewReference
{
  return [self logChangeAsMoney: FALSE resourceId: aResourceId oldValue: anOldValue newValue: aNewValue oldReference: anOldReference newReference: aNewReference];
}

/**/
- (BOOL) logChangeAsPassword: (int) aResourceId oldValue: (char *) anOldValue newValue: (char *) aNewValue oldReference: (long) anOldReference newReference: (long) aNewReference
{
  return [self logChangeAsPassword: FALSE resourceId: aResourceId oldValue: anOldValue newValue: aNewValue oldReference: anOldReference newReference: aNewReference];
}

/**/
+ (void) setActivateChangeLog: (BOOL) aValue
{
  myChangeLogActivated = aValue;
}

/**/
+ (long) auditEventCurrentUser: (int) anEventId additional: (char*) anAdditional station: (int) aStation logRemoteSystem: (BOOL) logRemoteSystem
{
	USER user = [[UserManager getInstance] getUserLoggedIn];
  return [Audit auditEvent: user eventId: anEventId additional: anAdditional station: aStation logRemoteSystem: logRemoteSystem];
}

/**/
+ (long) auditEventCurrentUserWithDate: (int) anEventId additional: (char*) anAdditional station: (int) aStation datetime: (datetime_t) aDateTime logRemoteSystem: (BOOL) logRemoteSystem
{
	USER user = [[UserManager getInstance] getUserLoggedIn];
  return [Audit auditEventWithDate: user eventId: anEventId additional: anAdditional station: aStation datetime: aDateTime logRemoteSystem: logRemoteSystem];
}

/**/
+ (long) auditEvent: (int) anEventId additional: (char*) anAdditional station: (int) aStation logRemoteSystem: (BOOL) logRemoteSystem
{
	return [Audit auditEvent: NULL eventId: anEventId additional: anAdditional station: aStation logRemoteSystem: logRemoteSystem];
}


/**/
+ (long) auditEvent: (USER) aUser eventId: (int) anEventId additional: (char*) anAdditional station: (int) aStation logRemoteSystem: (BOOL) logRemoteSystem
{

	id telesup;
	int userId = 0;
	int systemType;
  id event;

	if (aUser) userId = [aUser getUserId]; 

	systemType = SystemType_CIM;

	if (logRemoteSystem) {
		if ([[Acceptor getInstance] isTelesupRunning]) systemType = SystemType_CMP;
		if ([[TelesupScheduler getInstance] inTelesup]) systemType = SystemType_PIMS;
	}
  
  
	telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];

  event = [[EventManager getInstance] getEvent: anEventId];
  /* ************************* logcoment
   * if (event == NULL) {
    doLog(0,"Error: el evento de auditoria %d no se encuentra registrado\n", anEventId);
  }*/


	/* supervisa si:
	1.existe la supervision
	2.puede ejecutar el modulo
	3.el modulo tiene configurado online
	4.esta configurada online el envio de alarmas en la telesup
	5.la audit es critica */ 	

	if ( telesup && 
				([telesup getInformAlarmsByTransaction] && 
				event != NULL && [event isCritical]) &&
				([[CommercialStateMgr getInstance] canExecuteModule: ModuleCode_SEND_ALARMS] &&
				[[[CommercialStateMgr getInstance] getModuleByCode: ModuleCode_SEND_ALARMS] getOnline]) ) {
		[[TelesupScheduler getInstance] setCommunicationIntention: CommunicationIntention_INFORM_ALARMS];
		[[TelesupScheduler getInstance] startTelesupInBackground];
	}

	return [[[Persistence getInstance] getAuditDAO] storeAudit: anEventId userId: userId
		date: [SystemTime getLocalTime] station: aStation additional: anAdditional systemType: systemType];

}

/**/
+ (long) auditEventWithDate: (USER) aUser eventId: (int) anEventId
				additional: (char*) anAdditional station: (int) aStation datetime: (datetime_t) aDateTime logRemoteSystem: (BOOL) logRemoteSystem
{

	id telesup;
	int systemType;
	int userId = 0;

	if (aUser) userId = [aUser getUserId]; 

	systemType = SystemType_CIM;

	if (logRemoteSystem) {
		if ([[Acceptor getInstance] isTelesupRunning]) systemType = SystemType_CMP;
		if ([[TelesupScheduler getInstance] inTelesup]) systemType = SystemType_PIMS;
	}


	/* supervisa si:
	1.existe la supervision
	2.puede ejecutar el modulo
	3.el modulo tiene configurado online
	4.esta configurada online el envio de alarmas en la telesup
	5.la audit es critica */ 	

	telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];

	if ( telesup && 
				[[CommercialStateMgr getInstance] canExecuteModule: ModuleCode_SEND_ALARMS] &&
				[[[CommercialStateMgr getInstance] getModuleByCode: ModuleCode_SEND_ALARMS] getOnline] &&
				[telesup getInformAlarmsByTransaction] && 
				[[EventManager getInstance] getEvent: anEventId] != NULL && [[[EventManager getInstance] getEvent: anEventId] isCritical] ) {

		[[TelesupScheduler getInstance] setCommunicationIntention: CommunicationIntention_INFORM_ALARMS];
		[[TelesupScheduler getInstance] startTelesupInBackground];
	}

	return [[[Persistence getInstance] getAuditDAO] storeAudit: anEventId userId: userId
		date: aDateTime station: aStation additional: anAdditional systemType: systemType]; 

}				


/**/
- (void) setAlwaysLog: (BOOL) aValue { myAlwaysLog = aValue; }

@end
