#include "DoorDAO.h"
#include "SettingsExcepts.h"
#include "ordcltn.h"
#include "system/db/all.h"
#include "DataSearcher.h"
#include "util.h"
#include "Audit.h"
#include "MessageHandler.h"
#include "system/util/all.h"
#include "Audit.h"
#include "ResourceStringDefs.h"
#include "CimManager.h"

static id singleInstance = NULL;

@implementation DoorDAO

- (id) newDoorFromRecordSet: (id) aRecordSet; 

/**/
+ new
{
	if (!singleInstance) singleInstance = [super new];
	return singleInstance;
}

/**/
- free
{
	return [super free];
}

/**/
+ getInstance
{
	return [self new];
}

/**/
- (id) newDoorFromRecordSet: (id) aRecordSet
{
	DOOR obj;
	char buffer[61];
	char fieldName[30]; 
	id timeLock;
	int i;

	obj = [Door new];

	[obj setDoorId: [aRecordSet getShortValue: "DOOR_ID"]];
	[obj setDoorName: [aRecordSet getStringValue: "DOOR_NAME" buffer: buffer]];
	[obj setDoorType: [aRecordSet getCharValue: "DOOR_TYPE"]];
	[obj setKeyCount: [aRecordSet getCharValue: "KEY_COUNT"]];
	[obj setHasSensor: [aRecordSet getCharValue: "HAS_SENSOR"]];
	[obj setAutomaticLockTime: [aRecordSet getShortValue: "AUTOMATIC_LOCK_TIME"]];
	[obj setDelayOpenTime: [aRecordSet getShortValue: "DELAY_OPEN_TIME"]];
	[obj setAccessTime: [aRecordSet getShortValue: "ACCESS_TIME"]];
	[obj setMaxOpenTime: [aRecordSet getShortValue: "MAX_OPEN_TIME"]];
	[obj setFireAlarmTime: [aRecordSet getShortValue: "FIRE_ALARM_TIME"]];
	[obj setHasElectronicLock: [aRecordSet getCharValue: "HAS_ELECTRONIC_LOCK"]];
	[obj setFireTime: [aRecordSet getShortValue: "FIRE_TIME"]];
	[obj setBehindDoorId: [aRecordSet getShortValue: "BEHIND_DOOR_ID"]];

	for (i=1; i<8; ++i) {

		// Franja 1
		timeLock = [TimeLock new];
		[timeLock setDayOfWeek: i-1];

		sprintf(fieldName, "TIME_UNLOCK1_%d_FROM", i); 
  	[timeLock setFromMinute: [aRecordSet getShortValue: fieldName]];

		sprintf(fieldName, "TIME_UNLOCK1_%d_TO", i); 
  	[timeLock setToMinute: [aRecordSet getShortValue: fieldName]];

		[obj addTimeLock: timeLock];


		// Franja 2
		timeLock = [TimeLock new];
		[timeLock setDayOfWeek: i-1];

		sprintf(fieldName, "TIME_UNLOCK2_%d_FROM", i); 
  	[timeLock setFromMinute: [aRecordSet getShortValue: fieldName]];

		sprintf(fieldName, "TIME_UNLOCK2_%d_TO", i); 
  	[timeLock setToMinute: [aRecordSet getShortValue: fieldName]];

		[obj addTimeLock: timeLock];

	}

	[obj setDeleted: [aRecordSet getCharValue: "DELETED"]];
	[obj setLockHardwareId: [aRecordSet getCharValue: "LOCKER_ID"]];
	[obj setPlungerHardwareId: [aRecordSet getCharValue: "PLUNGER_ID"]];
	[obj setTUnlockEnable: [aRecordSet getCharValue: "TUNLOCK_ENABLE"]];
	[obj setSensorType: [aRecordSet getCharValue: "SENSOR_TYPE"]];

	return obj;
}

/**/
- (COLLECTION) loadAll
{
	COLLECTION collection = [Collection new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "doors" 
			filter: "" orderFields: "DOOR_ID"];
	DOOR obj;
	
	[myRecordSet open];
  
	while ( [myRecordSet moveNext] ) {
		// agrego el usuario a la coleccion solo si no se encuentra borrado
		obj = [self newDoorFromRecordSet: myRecordSet];
		[collection add: obj]; // Marcelo - Se traen todas siempre. Luego se habilitaran los dispositivos que esten detras de ella dependiendo de que la puerta este o no habilitada
		//if (!([obj isDeleted])) [collection add: obj];
		//else [obj free];
	}

	[myRecordSet free];
  
	return collection;
}

/**/
- (id) loadById: (unsigned long) anId
{
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "doors" filter: "" orderFields: "DOOR_ID"];
	
	id obj = NULL;

	[myRecordSet open];

	if ([myRecordSet findById: "DOOR_ID" value: anId]) {
		obj = [self newDoorFromRecordSet: myRecordSet];
		if (![obj isDeleted])	return obj;
	}
  
	[myRecordSet free];
  
	return NULL;
}

/**/
- (COLLECTION) loadCompleteList
{
	COLLECTION collection = [Collection new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "doors" 
			filter: "" orderFields: "DOOR_ID"];
	DOOR obj;
	
	[myRecordSet open]; 

	while ( [myRecordSet moveNext] ) {
		obj = [self newDoorFromRecordSet: myRecordSet];
		[collection add: obj];
	}

	[myRecordSet free];
  
	return collection;
}

/**/
- (void) store: (id) anObject
{
	id timeLocks;
	int i;
	int j;
	char fieldName[30];
	char buffer[60];
	AUDIT audit;
	char oldBehindDoorStr[40];
	char newBehindDoorStr[40];
	char strDateOld[10];
	char strDateNew[10];
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSetWithFilter: "doors" filter: "" orderFields: "DOOR_ID"];
	ABSTRACT_RECORDSET myRecordSetBck;
	volatile BOOL updateRecord = FALSE;

  [self validateFields: anObject];
		
	TRY

		[myDataSearcher setRecordSet: myRecordSet];
		[myDataSearcher addShortFilter: "DOOR_ID" operator: "!=" value: [anObject getDoorId]];  
		[myDataSearcher addStringFilter: "NAME" operator: "=" value: [anObject getDoorName]];
		[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];
	
		[myRecordSet open];
	
		if ([anObject getDoorId] == 0) 
			if ([myDataSearcher find]) THROW(DAO_DUPLICATED_DOOR_EX);    
	
		[self validateFields: anObject];
	
		if ([anObject isDeleted]) {
			updateRecord = TRUE;
			audit = [[Audit new] initAuditWithCurrentUser: Event_DELETE_LOCK additional: [anObject getDoorName] station: [anObject getDoorId] logRemoteSystem: TRUE];
			[myRecordSet findById: "DOOR_ID" value: [anObject getDoorId]];
		} else if ([anObject getDoorId] != 0) {
			updateRecord = TRUE;
			[myRecordSet findById: "DOOR_ID" value: [anObject getDoorId]];
			audit = [[Audit new] initAuditWithCurrentUser: Event_EDIT_LOCK additional: [anObject getDoorName] station: [anObject getDoorId] logRemoteSystem: TRUE];
		} else {
			[myRecordSet add];
			audit = [[Audit new] initAuditWithCurrentUser: Event_NEW_LOCK additional: [anObject getDoorName] station: 0 logRemoteSystem: TRUE];
			[audit setAlwaysLog: TRUE];
		}

		// LOG DE CAMBIOS
    [audit logChangeAsString: RESID_Door_NAME oldValue: [myRecordSet getStringValue: "DOOR_NAME" buffer: buffer] newValue: [anObject getDoorName]];

		[audit logChangeAsResourceString: FALSE 
			resourceId: RESID_Door_DOOR_TYPE 
			resourceStringBase: RESID_Door_DOOR_TYPE
			oldValue: [myRecordSet getCharValue: "DOOR_TYPE"] 
			newValue: [anObject getDoorType]
			oldReference: [myRecordSet getCharValue: "DOOR_TYPE"] 
			newReference: [anObject getDoorType]]; 

    [audit logChangeAsInteger: RESID_Door_KEY_COUNT oldValue: [myRecordSet getCharValue: "KEY_COUNT"] newValue: [anObject getKeyCount]];
    [audit logChangeAsBoolean: RESID_Door_HAS_SENSOR oldValue: [myRecordSet getCharValue: "HAS_SENSOR"] newValue: [anObject hasSensor]];
    [audit logChangeAsInteger: RESID_Door_AUTOMATIC_LOCK_TIME oldValue: [myRecordSet getShortValue: "AUTOMATIC_LOCK_TIME"] newValue: [anObject getAutomaticLockTime]];
    [audit logChangeAsInteger: RESID_Door_DELAY_OPEN_TIME oldValue: [myRecordSet getShortValue: "DELAY_OPEN_TIME"] newValue: [anObject getDelayOpenTime]];
    [audit logChangeAsInteger: RESID_Door_ACCESS_TIME oldValue: [myRecordSet getShortValue: "ACCESS_TIME"] newValue: [anObject getAccessTime]];
    [audit logChangeAsInteger: RESID_Door_MAX_OPEN_TIME oldValue: [myRecordSet getShortValue: "MAX_OPEN_TIME"] newValue: [anObject getMaxOpenTime]];
    [audit logChangeAsInteger: RESID_Door_FIRE_ALARM_TIME oldValue: [myRecordSet getShortValue: "FIRE_ALARM_TIME"] newValue: [anObject getFireAlarmTime]];
    [audit logChangeAsBoolean: RESID_Door_HAS_ELECTRONIC_LOCK oldValue: [myRecordSet getCharValue: "HAS_ELECTRONIC_LOCK"] newValue: [anObject hasElectronicLock]];

		oldBehindDoorStr[0] = '\0';
		newBehindDoorStr[0] = '\0';

		if ([myRecordSet getShortValue: "BEHIND_DOOR_ID"] != 0)
			strcpy (oldBehindDoorStr, [[[[CimManager getInstance] getCim] getDoorById: [myRecordSet getShortValue: "BEHIND_DOOR_ID"]] getDoorName]);

		if ([anObject getBehindDoorId] != 0)
			strcpy(newBehindDoorStr, [[[[CimManager getInstance] getCim] getDoorById: [anObject getBehindDoorId]] getDoorName]);

    [audit logChangeAsString: FALSE 
					resourceId: RESID_Door_BEHIND_DOOR_ID 
					oldValue: oldBehindDoorStr 						
					newValue: newBehindDoorStr
					oldReference: [myRecordSet getShortValue: "BEHIND_DOOR_ID"] 
					newReference: [anObject getBehindDoorId]];

    [audit logChangeAsInteger: RESID_Door_TUNLOCK_ENABLE oldValue: [myRecordSet getCharValue: "TUNLOCK_ENABLE"] newValue: [anObject getTUnlockEnable]];

		[audit logChangeAsResourceString: FALSE 
			resourceId: RESID_Door_SENSOR_TYPE 
			resourceStringBase: RESID_Door_SENSOR_TYPE
			oldValue: [myRecordSet getCharValue: "SENSOR_TYPE"] 
			newValue: [anObject getSensorType]
			oldReference: [myRecordSet getCharValue: "SENSOR_TYPE"] 
			newReference: [anObject getSensorType]]; 

    
		[myRecordSet setStringValue: "DOOR_NAME" value: [anObject getDoorName]];
		[myRecordSet setCharValue: "DOOR_TYPE" value: [anObject getDoorType]];
		[myRecordSet setCharValue: "KEY_COUNT" value: [anObject getKeyCount]];
		[myRecordSet setCharValue: "HAS_SENSOR" value: [anObject hasSensor]]; 
		[myRecordSet setShortValue: "AUTOMATIC_LOCK_TIME" value: [anObject getAutomaticLockTime]];
		[myRecordSet setShortValue: "DELAY_OPEN_TIME" value: [anObject getDelayOpenTime]];
		[myRecordSet setShortValue: "ACCESS_TIME" value: [anObject getAccessTime]];
		[myRecordSet setShortValue: "MAX_OPEN_TIME" value: [anObject getMaxOpenTime]];
		[myRecordSet setShortValue: "FIRE_ALARM_TIME" value: [anObject getFireAlarmTime]];
		[myRecordSet setCharValue: "HAS_ELECTRONIC_LOCK" value: [anObject hasElectronicLock]];
		[myRecordSet setShortValue: "FIRE_TIME" value: [anObject getFireTime]];
		[myRecordSet setShortValue: "BEHIND_DOOR_ID" value: [anObject getBehindDoorId]];

		timeLocks = [anObject getTimeLocks];

		i = 0;
		j = 0;

		while (i<[timeLocks size]) {
	
			// Franja 1
			sprintf(fieldName, "TIME_UNLOCK1_%d_FROM", [[timeLocks at: i] getDayOfWeek] + 1);
      
	    strcpy(strDateOld, [self formatMinutesToHourStr: [myRecordSet getShortValue: fieldName] buffer: buffer]);
      strcpy(strDateNew, [self formatMinutesToHourStr: [[timeLocks at: i] getFromMinute] buffer: buffer]);
      
  		[audit logChangeAsString: FALSE
  															resourceId: RESID_Door_TIME_UNLOCK1_1_FROM + j 
  															oldValue: strDateOld 
  															newValue: strDateNew 
  															oldReference: [myRecordSet getShortValue: fieldName] 
  															newReference: [[timeLocks at: i] getFromMinute]];

			[myRecordSet setShortValue: fieldName value: [[timeLocks at: i] getFromMinute]];

			++j;			

			sprintf(fieldName, "TIME_UNLOCK1_%d_TO", [[timeLocks at: i] getDayOfWeek] + 1);
      
	    strcpy(strDateOld, [self formatMinutesToHourStr: [myRecordSet getShortValue: fieldName] buffer: buffer]);
      strcpy(strDateNew, [self formatMinutesToHourStr: [[timeLocks at: i] getToMinute] buffer: buffer]);
      
  		[audit logChangeAsString: FALSE
  															resourceId: RESID_Door_TIME_UNLOCK1_1_FROM + j 
  															oldValue: strDateOld 
  															newValue: strDateNew 
  															oldReference: [myRecordSet getShortValue: fieldName] 
  															newReference: [[timeLocks at: i] getToMinute]];

			[myRecordSet setShortValue: fieldName value: [[timeLocks at: i] getToMinute]];

			++i;
			++j;

			// Franja 2
			sprintf(fieldName, "TIME_UNLOCK2_%d_FROM", [[timeLocks at: i] getDayOfWeek] + 1);
      
	    strcpy(strDateOld, [self formatMinutesToHourStr: [myRecordSet getShortValue: fieldName] buffer: buffer]);
      strcpy(strDateNew, [self formatMinutesToHourStr: [[timeLocks at: i] getFromMinute] buffer: buffer]);
      
  		[audit logChangeAsString: FALSE
  															resourceId: RESID_Door_TIME_UNLOCK1_1_FROM + j 
  															oldValue: strDateOld 
  															newValue: strDateNew 
  															oldReference: [myRecordSet getShortValue: fieldName] 
  															newReference: [[timeLocks at: i] getFromMinute]];	    

			[myRecordSet setShortValue: fieldName value: [[timeLocks at: i] getFromMinute]];
			
			++j;
	
			sprintf(fieldName, "TIME_UNLOCK2_%d_TO", [[timeLocks at: i] getDayOfWeek] + 1);
      
	    strcpy(strDateOld, [self formatMinutesToHourStr: [myRecordSet getShortValue: fieldName] buffer: buffer]);
      strcpy(strDateNew, [self formatMinutesToHourStr: [[timeLocks at: i] getToMinute] buffer: buffer]);      
      
  		[audit logChangeAsString: FALSE
  															resourceId: RESID_Door_TIME_UNLOCK1_1_FROM + j 
  															oldValue: strDateOld 
  															newValue: strDateNew 
                                oldReference: [myRecordSet getShortValue: fieldName] 
  															newReference: [[timeLocks at: i] getToMinute]];

			[myRecordSet setShortValue: fieldName value: [[timeLocks at: i] getToMinute]];

			++i;
			++j;
		}

		[myRecordSet setCharValue: "DELETED" value: [anObject isDeleted]];
		[myRecordSet setCharValue: "LOCKER_ID" value: [anObject getLockHardwareId]];
		[myRecordSet setCharValue: "PLUNGER_ID" value: [anObject getPlungerHardwareId]];
		[myRecordSet setCharValue: "TUNLOCK_ENABLE" value: [anObject getTUnlockEnable]];
		[myRecordSet setCharValue: "SENSOR_TYPE" value: [anObject getSensorType]];

		[myRecordSet save];

		[audit setStation: [myRecordSet getShortValue: "DOOR_ID"]];
    [audit saveAudit];
    [audit free];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "doors_bck"]) {
			myRecordSetBck = [dbConnection createRecordSetWithFilter: "doors_bck" filter: "" orderFields: "DOOR_ID"];
	
			if (updateRecord) [self doUpdateBackupById: "DOOR_ID" value: [myRecordSet getShortValue: "DOOR_ID"] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "doors_bck"];
			else [self doAddBackup: myRecordSetBck currentRecordSet: myRecordSet tableName: "doors_bck"];
		}

	FINALLY

		[myRecordSet free];
	
	END_TRY
}

/**/
- (char*) formatMinutesToHourStr: (int) aMinutes buffer: (char*) aBuffer
{
	int hours;
  int minutes;
  int value;
  char auxStr[10];
  
  // armo la hora formateada
  value = aMinutes;
  hours = (value / 60);
  minutes = (value % 60);
  aBuffer[0] = '\0';
  sprintf(auxStr,"%d",hours);
  if (strlen(auxStr) == 1)
    strcat(aBuffer,"0");
  
  strcat(aBuffer,auxStr);
  strcat(aBuffer,":");
  sprintf(auxStr,"%d",minutes);
  if (strlen(auxStr) == 1)
    strcat(aBuffer,"0");
  
  strcat(aBuffer,auxStr);
  
  return aBuffer;
}


/**/
- (void) validateFields: (id) anObject
{
	COLLECTION innerDoors;
	int i;

	if (([anObject getDelayOpenTime] < 0) || ([anObject getDelayOpenTime] > 360))
    THROW(DAO_DELAY_OPEN_TIME_INCORRECT_EX);				

	if (([anObject getAccessTime] < 0) || ([anObject getAccessTime] > 300))
    THROW(DAO_ACCESS_TIME_INCORRECT_EX);				

	if (([anObject getMaxOpenTime] < 15) || ([anObject getMaxOpenTime] > 600))
    THROW(DAO_MAX_OPEN_TIME_INCORRECT_EX);				

	if (([anObject getFireAlarmTime] < 0) || ([anObject getFireAlarmTime] > 300))
    THROW(DAO_FIRE_ALARM_TIME_INCORRECT_EX);			

	if ([anObject getAutomaticLockTime] < 3)
		THROW(DAO_AUTOMATIC_LOCK_TIME_INCORRECT_EX);

	// Chequea configuracion con la puerta externa
	if ([anObject getOuterDoor] != NULL) {
		if ([[anObject getOuterDoor] getKeyCount] > [anObject getKeyCount])
			THROW(DAO_OUTER_DOOR_KEY_COUNT_BIGGER_THAN_INNER_DOOR_EX);
	}

	// Chequea que ninguna puerta interna tenga un keycount menor
	innerDoors = [[[CimManager getInstance] getCim] getDoorsBehind: anObject];
	for (i = 0; i < [innerDoors size]; ++i) {
		if ([anObject getKeyCount] > [[innerDoors at: i] getKeyCount])
			THROW(DAO_OUTER_DOOR_KEY_COUNT_BIGGER_THAN_INNER_DOOR_EX);
	}
	[innerDoors free];

}


@end
