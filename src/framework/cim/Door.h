#ifndef DOOR_H
#define DOOR_H

#define DOOR id

#include "Object.h"
#include "system/lang/all.h"
#include "CimDefs.h"
#include "AcceptorSettings.h"
#include "TimeLock.h"

#define DOOR_NAME_SIZE	40

typedef enum {
	DoorState_UNDEFINED,
	DoorState_OPEN,
	DoorState_CLOSE
} DoorState;

typedef enum {
	LockState_UNDEFINED,
	LockState_UNLOCK,
	LockState_LOCK
} LockState;

typedef enum {
	SensorType_UNDEFINED,
	SensorType_NONE,
	SensorType_LOCKER,
	SensorType_PLUNGER,
	SensorType_BOTH,
	SensorType_PLUNGER_EXT
} SensorType;


/**
 * 
 */
@interface Door :  Object
{

/** Identificador de puerta */
	int myDoorId;

/** Tipo de puerta */
	DoorType myDoorType;

/** Cantidad de clave necesarias para abrir la puerta */
	int myKeyCount;

/** Indica si la puerta posee una cerradura electronica */
	BOOL myHasElectronicLock;

/** Indica si la puerta posee sensor de apertura/cierre */
	BOOL myHasSensor;

/** Tiempo bloqueo puerta de caja (en seg): es el tiempo maximo en segundos que puede transcurrir desde que se 
		desbloquea la cerradura electronica hasta que se detecta puerta abierta. Si se llega a este tiempo sin haber 
		detectado la apertura de puerta automaticamente se bloqueara la cerradura. */
	int myAutomaticLockTime;               

/** Tiempo de apertura retrasada (en seg): corresponde al tiempo que se debe esperar para abrir la cerradura electronica una vez
	  que se dieron todas las condiciones para realizar la extraccion. */
	int myDelayOpenTime;

/** Tiempo de acceso a la puerta (en seg): es el tiempo que puede transcurrir como maximo desde que transcurre el 
		DelayOpenTime hasta que el usuario abre la puerta. Si la puerta no es abierta en este tiempo, automaticamente se
		cancela la operacion */
	int myAccessTime;

/** Tiempo maximo de apuertura de puerta (en seg): Es el tiempo maximo que puede permanecer la puerta abierta durante una
		extraccion antes de mostrar la advertencia */
	int myMaxOpenTime;

/** Tiempo de disparo de alarma (en seg): Es el tiempo que puede permanecer abierta la puerta hasta que se dispara la alarma
		(el tiempo comienza a transcurrir desde que se dispara la advertencia). */
	int myFireAlarmTime;

/*
	Los tiempos normalmente se dan en este orden:

	   DelayOpenTime          AccessTime          AutomaticLockTime        MaxOpenTime				   FireAlarmTime
  |----------------------|-------------------<|---------------------<|----------------------<|------------------|

El usuario           El sistema           El usuario             El usuario               El usuario
solicita la      solicita nuevamente      se loguea            abre la puerta           no abre la puerta
apertura           el login durante    y se desbloquea la      
 (login)         el tiempo AccessTime     cerradura
 

 */

/** Nombre de la puerta */
	char myDoorName[DOOR_NAME_SIZE + 1];

/** Aceptadores asociados a esta puerta */
	COLLECTION myAcceptorSettingsList;

 /** Puerta detras de otra */
	int myBehindDoorId;

 /** Disparo alarma */
	int myFireTime;
	
 /** Esta eliminada */
	BOOL myIsDeleted;
	
/** Lista de timelocks asociados */
  COLLECTION myTimeLocks;

/** Hardware Id del sensor de la puerta */
	int myPlungerHardwareId;

/** Hardware Id de la cerradura de la puerta */
	int myLockHardwareId;

/** Estado actual de la puerta */
	DoorState myDoorState;

/** Estado actual de la cerradura */
	LockState myLockState;

/** Observer de la puerta para notificacion de eventos */
	id myObserver;

	int myTUnlockEnable;

	SensorType mySensorType;

	DOOR myOuterDoor;

	COLLECTION myUsers;
}

/**/
- (void) initDoor;

/**/
- (void) setPlungerHardwareId: (int) aHardwareId;
- (int) getPlungerHardwareId;

/**/
- (void) setLockHardwareId: (int) aHardwareId;
- (int) getLockHardwareId;

/**/
- (void) setDoorId: (int) aValue;
- (int) getDoorId;

/**/
- (void) setDoorName: (char *) aDoorName;
- (char *) getDoorName;

/**/
- (void) setDoorType: (DoorType) aValue;
- (DoorType) getDoorType;

/**/
- (void) setHasElectronicLock: (BOOL) aValue;
- (BOOL) hasElectronicLock;

/**/
- (void) setHasSensor: (BOOL) aValue;
- (BOOL) hasSensor;

/**/
- (void) setAutomaticLockTime: (int) aValue;
- (int) getAutomaticLockTime;

/**/
- (void) setDelayOpenTime: (int) aValue;
- (int) getDelayOpenTime;

/**/
- (void) setMaxOpenTime: (int) aValue;
- (int) getMaxOpenTime;

/**/
- (void) setFireAlarmTime: (int) aValue;
- (int) getFireAlarmTime;

/**/
- (void) setAccessTime: (int) aValue;
- (int) getAccessTime;

/**/
- (void) setKeyCount: (int) aValue;
- (int) getKeyCount;

/**/
- (void) addAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings;
- (COLLECTION) getAcceptorSettingsList;

/**/
- (void) setBehindDoorId: (int) aValue;
- (int) getBehindDoorId;
- (BOOL) isInnerDoor;

/**/
- (void) setOuterDoor: (DOOR) aDoor;
- (DOOR) getOuterDoor;

/**/
- (void) setFireTime: (int) aValue;
- (int) getFireTime;

/**/
- (void) setDeleted: (BOOL) aValue;
- (BOOL) isDeleted;

/**/
- (void) addTimeLock: (TIME_LOCK) aTimeLock;
- (COLLECTION) getTimeLocks;

/**
 *  Retorna TRUE si la puerta puede ser abierta, teniendo en cuenta
 *  el dia y la hora actual contra los time locks definidos
 */  
- (BOOL) canOpenDoor;

- (BOOL) canOpenDoor: (datetime_t) aDateTime;

#ifdef __DEBUG_CIM
/**/
- (void) debug;
#endif

/**/
- (void) applyChanges;

/**/
- (void) restore;

/**/
- (void) setObserver: (id) anObserver;

/**/
- (void) setLockState: (LockState) aValue;
- (LockState) getLockState;

/**/
- (void) setDoorState: (DoorState) aValue;
- (DoorState) getDoorState;

/**/
- (void) setTUnlockEnable: (int) aValue;
- (int) getTUnlockEnable;

/**/
- (void) setSensorType: (SensorType) aValue;
- (SensorType) getSensorType;

/*
 * Retorna la lista de usuarios asociados a la puerta
 */
- (COLLECTION) getUsers;

/*
 * Agrega en memoria el usuario a la puerta
 */
- (void) addUserToDoor: (id) anUser;

/*
 * Quita de memoria el usuario de la puerta
 */
- (void) removeUserFromDoor: (id) anUser;


@end

#endif
