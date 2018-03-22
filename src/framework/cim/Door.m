#include "Door.h"
#include "DoorDAO.h"
#include "Persistence.h"
#include "SafeBoxHAL.h"
#include "CimEventDispatcher.h"
#include "Audit.h"
#include "POSEventAcceptor.h"
#include "CimGeneralSettings.h"
#include "UserManager.h"

@implementation Door

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myDoorId = 0;
	myDoorType = DoorType_UNDEFINED;
	myHasElectronicLock = FALSE;
	myAcceptorSettingsList = [Collection new];
	myAutomaticLockTime = 10;
	myDelayOpenTime = 15;
	myMaxOpenTime = 60;
	myFireAlarmTime = 60;
	myHasSensor = FALSE;
	myAccessTime = 60;
	*myDoorName = '\0';
	myKeyCount = 1;
	myIsDeleted = TRUE;
	myTimeLocks = [Collection new];
	myPlungerHardwareId = 0;
	myLockHardwareId = 0;
	myDoorState = DoorState_UNDEFINED;
	myObserver = NULL;
	myLockState = LockState_UNDEFINED;
	myTUnlockEnable = 0;
	myOuterDoor = NULL;
	myUsers = [Collection new];
	mySensorType = SensorType_UNDEFINED;
	return self;
}

/**/
- free
{
	[myAcceptorSettingsList	free];
	[myTimeLocks freeContents];
	[myTimeLocks free];
	[myUsers free];
	return [super free];
}

/**/
- (void) initDoor
{

			    //************************* logcoment
//	doLog(0,"initDoor = %d, %d\n", myPlungerHardwareId, myLockHardwareId);

	[[CimEventDispatcher getInstance] registerDevice: myPlungerHardwareId 
		deviceType: DeviceType_PLUNGER 
		object: self];

	[[CimEventDispatcher getInstance] registerDevice: myLockHardwareId 
			deviceType: DeviceType_LOCKER 
			object: self];
}

/**/
- (void) setPlungerHardwareId: (int) aHardwareId { myPlungerHardwareId = aHardwareId; }
- (int) getPlungerHardwareId { return myPlungerHardwareId; }

/**/
- (void) setLockHardwareId: (int) aHardwareId { myLockHardwareId = aHardwareId; }
- (int) getLockHardwareId { return myLockHardwareId; }

/**/
- (void) setDoorId: (int) aValue { myDoorId = aValue; }
- (int) getDoorId { return myDoorId; }

/**/
- (void) setDoorName: (char *) aDoorName { stringcpy(myDoorName, aDoorName); }
- (char *) getDoorName { return myDoorName; }

/**/
- (void) setDoorType: (DoorType) aValue { myDoorType = aValue; }
- (DoorType) getDoorType { return myDoorType; }

/**/
- (void) setHasElectronicLock: (BOOL) aValue { myHasElectronicLock = aValue; }
- (BOOL) hasElectronicLock { return myHasElectronicLock; }

/**/
- (void) setHasSensor: (BOOL) aValue { myHasSensor = aValue; }
- (BOOL) hasSensor { return myHasSensor; }

/**/
- (void) setAutomaticLockTime: (int) aValue { myAutomaticLockTime = aValue; }
- (int) getAutomaticLockTime { return myAutomaticLockTime; }

/**/
- (void) setDelayOpenTime: (int) aValue { myDelayOpenTime = aValue; }
- (int) getDelayOpenTime { return myDelayOpenTime; }

/**/
- (void) setMaxOpenTime: (int) aValue { myMaxOpenTime = aValue; }
- (int) getMaxOpenTime { return myMaxOpenTime; }

/**/
- (void) setFireAlarmTime: (int) aValue { myFireAlarmTime = aValue; }
- (int) getFireAlarmTime { return myFireAlarmTime; }

/**/
- (void) setAccessTime: (int) aValue { myAccessTime = aValue; }
- (int) getAccessTime { return myAccessTime; }

/**/
- (void) setKeyCount: (int) aValue { myKeyCount = aValue; }
- (int) getKeyCount { return myKeyCount; }

/**/
- (void) addAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings
{
	[myAcceptorSettingsList remove: anAcceptorSettings];
	[myAcceptorSettingsList add: anAcceptorSettings];
	[anAcceptorSettings setDoor: self];
}

/**/
- (COLLECTION) getAcceptorSettingsList
{
	return myAcceptorSettingsList;
}

/**/
- (void) setBehindDoorId: (int) aValue { myBehindDoorId = aValue; }
- (int) getBehindDoorId { return myBehindDoorId; }
- (BOOL) isInnerDoor { return myOuterDoor != NULL; }

/**/
- (void) setOuterDoor: (DOOR) aDoor { myOuterDoor = aDoor; }
- (DOOR) getOuterDoor { return myOuterDoor; }

/**/
- (void) setFireTime: (int) aValue { myFireTime = aValue; }
- (int) getFireTime { return myFireTime; }

/**/
- (void) setDeleted: (BOOL) aValue { myIsDeleted  = aValue; }
- (BOOL) isDeleted { return myIsDeleted; }

/**/
- (STR) str
{
	return myDoorName;
}

/**/
- (void) addTimeLock: (TIME_LOCK) aTimeLock
{
  [myTimeLocks add: aTimeLock];
}

/**/
- (COLLECTION) getTimeLocks
{
  return myTimeLocks;
}

/**/
- (void) onDoorOpen
{
	id userAdmin;
	//myDoorState = DoorState_OPEN;

	
	if ([self getSensorType] == SensorType_PLUNGER_EXT) {

		userAdmin = [[UserManager getInstance] getUser: 1];
		
		[Audit auditEvent: userAdmin eventId: AUDIT_CIM_DOOR_OPEN additional: myDoorName station: myDoorId logRemoteSystem: FALSE];

		[[ExtractionManager getInstance] generateExtraction: self user1: userAdmin  user2: userAdmin  bagNumber: "" bagTrackingMode: BagTrackingMode_NONE];

		return;
	}


	if (myObserver) [myObserver onDoorOpen: self];

	// me fijo si debo informar al POS del evento.
	// si bien estoy en el dooropen le mando el evento de dorrviolation porque al estar
	// conectado al POS el equipo esta bloqueado y no se puede hacer un dorrs access normal.
	// por ende se supone que si la puerta se abre es por una violacion de acceso.
	//if ([[POSEventAcceptor getInstance] isTelesupRunning])
	//	[[POSEventAcceptor getInstance] doorViolationEvent: myDoorId doorName: myDoorName];
}

/**/
- (void) onDoorClose
{
	// Audito el evento (solo si la puerta paso de abierta a cerrada
/*	if (myDoorState != DoorState_UNDEFINED)
		[Audit auditEventCurrentUser: AUDIT_CIM_DOOR_CLOSE additional: "" station: [self getDoorId] logRemoteSystem: FALSE];
*/
	//myDoorState = DoorState_CLOSE;

	if (myObserver) [myObserver onDoorClose: self];

	// me fijo si debo informar al POS del evento.
	//if ([[POSEventAcceptor getInstance] isTelesupRunning])
	//	[[POSEventAcceptor getInstance] doorCloseEvent: myDoorId doorName: myDoorName];
}

/**/
- (void) onLocked
{
	//myLockState = LockState_LOCK;
	if (myObserver) [myObserver onLocked: self];
}

/**/
- (void) onUnLocked
{
	//myLockState = LockState_UNLOCK;
	if (myObserver) [myObserver onUnLocked: self];
}

/**/
- (BOOL) canOpenDoor
{
  return [self canOpenDoor: [SystemTime getLocalTime]];
}

/**/
- (BOOL) canOpenDoor: (datetime_t) aDateTime
{
  struct tm brokenTime;
  int minutes;
  int i;
  TIME_LOCK timeLock;
  
  // Obtengo la fecha / hora actual
  [SystemTime decodeTime: aDateTime brokenTime: &brokenTime];
  minutes = brokenTime.tm_hour * 60 + brokenTime.tm_min;
  
  // Verifico si existe un TimeLock para el dia de la semana
  // y entre los minutes correspondientes, en cuyo caso
  // la puerta puede ser abierta
  for (i = 0; i < [myTimeLocks size]; ++i) {
    timeLock = [myTimeLocks at: i];
    if ([timeLock getDayOfWeek] == brokenTime.tm_wday &&
        minutes >= [timeLock getFromMinute] &&
        minutes < [timeLock getToMinute])
        return TRUE;
  }
  
  return FALSE;
}

/**/
- (void) setObserver: (id) anObserver
{
	myObserver = anObserver;
}


/**/
- (void) applyChanges
{
	id dao = [[Persistence getInstance] getDoorDAO];
	int i;

	[dao store: self];

	if ([self isDeleted]) {
		for (i=0; i<[myAcceptorSettingsList size]; i++) {
			if (![[myAcceptorSettingsList at: i] isDisabled]) {
				[[myAcceptorSettingsList at: i] setDisabled: TRUE];
				[[myAcceptorSettingsList at: i] applyChanges];
			}
		}
	}
}

/**/
- (void) setLockState: (LockState) aValue { myLockState = aValue; }
- (LockState) getLockState { return myLockState; }

/**/
- (void) setDoorState: (DoorState) aValue { myDoorState = aValue; }
- (DoorState) getDoorState { return myDoorState; }

/**/
- (void) setTUnlockEnable: (int) aValue { myTUnlockEnable = aValue; }
- (int) getTUnlockEnable { return myTUnlockEnable; }

/**/
- (void) setSensorType: (SensorType) aValue { mySensorType = aValue; }
- (SensorType) getSensorType { return mySensorType; }

/**/
- (COLLECTION) getUsers
{
	return myUsers;
}

/**/
- (void) addUserToDoor: (id) anUser
{
	[myUsers add: anUser];
}

/**/
- (void) removeUserFromDoor: (id) anUser
{
	int i = 0;
	
	for (i=0; i<[myUsers size]; ++i) 
		if ([[myUsers at: i] getUserId] == [anUser getUserId]) {
			[myUsers removeAt: i];
			return;
		}
}

/**/
- (void) restore
{
	id obj;
	COLLECTION tempTimeLocks;
	int i;
	id timeLock;
	id tempTimeLock;

	//Recupera el objeto de la persistencia
	obj =	[[[Persistence getInstance] getDoorDAO] loadById: [self getDoorId]];		

	[self setDoorName: [obj getDoorName]];
	[self setDoorType: [obj getDoorType]];
	[self setKeyCount: [obj getKeyCount]];
	[self setHasSensor: [obj hasSensor]];
	[self setAutomaticLockTime: [obj getAutomaticLockTime]];
	[self setDelayOpenTime: [obj getDelayOpenTime]];
	[self setAccessTime: [obj getAccessTime]];
	[self setMaxOpenTime: [obj getMaxOpenTime]];
	[self setFireAlarmTime: [obj getFireAlarmTime]];
	[self setHasElectronicLock: [obj hasElectronicLock]];
	[self setFireTime: [obj getFireTime]];
	[self setBehindDoorId: [obj getBehindDoorId]];

	[myTimeLocks freeContents];
	tempTimeLocks = [obj getTimeLocks];

	for (i=0; i<[tempTimeLocks size]; ++i) {

		tempTimeLock = [tempTimeLocks at: i];

		timeLock = [TimeLock new];
		[timeLock setDayOfWeek: [tempTimeLock getDayOfWeek]];
  	[timeLock setFromMinute: [tempTimeLock getFromMinute]];
  	[timeLock setToMinute: [tempTimeLock getToMinute]];

		[self addTimeLock: timeLock];

	}

	[self setLockHardwareId: [obj getLockHardwareId]];
	[self setPlungerHardwareId: [obj getPlungerHardwareId]];
	[self setTUnlockEnable: [obj getTUnlockEnable]];
	[self setSensorType: [obj getSensorType]];

	[obj free];	

}


#ifdef __DEBUG_CIM

/**/
- (void) debug
{
	int i;
	char *doorTypeStr[] = {"NO DEFINIDA", "COLLECTOR", "PERSONAL"};

	doLog(0,"Puerta -----------------------------------\n");
	doLog(0,"DoorId: %d\n", myDoorId);
	doLog(0,"Nombre: %s\n", myDoorName);
	doLog(0,"HasElectronicLock: %s\n", myHasElectronicLock ? "TRUE" : "FALSE");
	doLog(0,"HasSensor: %s\n", myHasSensor ? "TRUE" : "FALSE");
	doLog(0,"DoorType: %s\n", doorTypeStr[myDoorType]);
	doLog(0,"Validadores que pertenecen a esta puerta: \n");
	for (i = 0; i < [myAcceptorSettingsList size]; ++i) {
		doLog(0,"  AcceptorId: %d\n", [[myAcceptorSettingsList at: i] getAcceptorId]);
	}

}


#endif

@end

