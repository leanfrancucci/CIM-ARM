#ifndef SAFE_BOX_HAL_H
#define SAFE_BOX_HAL_H

#define SAFE_BOX_HAL id

#include <Object.h>
#include "safeBoxMgr.h"
#include "system/util/all.h"

#define MAX_DATA_SIZE				248

/**/
typedef enum {
	AlarmState_ON
 ,AlarmState_OFF
} AlarmState;

/**/
typedef enum {
  DeviceType_SAFEBOX
 ,DeviceType_VALIDATOR
 ,DeviceType_LOCKER
 ,DeviceType_PLUNGER
 ,DeviceType_POWER
 ,DeviceType_HARDWARE_SYSTEM
 ,DeviceType_BATTERY
 ,DeviceType_STACKER_SENSOR
 ,DeviceType_LOCKER_ERROR_STATUS
} DeviceType;

/**/
typedef enum {
	BatteryStatus_LOW
 ,BatteryStatus_REMOVED
 ,BatteryStatus_OK
} BatteryStatus;

/**/
typedef enum {
	PowerStatus_EXTERNAL
 ,PowerStatus_BACKUP
} PowerStatus;

/**/
typedef enum {
  HardwareSystemStatus_UNDEFINED = -1
 ,HardwareSystemStatus_PRIMARY
 ,HardwareSystemStatus_SECONDARY
} HardwareSystemStatus;

/**/
typedef enum {
	MemoryStatus_UNDEFINED = -1
 ,MemoryStatus_OK
 ,MemoryStatus_FAILURE
} MemoryStatus;

/**/
typedef struct {
	unsigned char hardwareId;
	unsigned char event;
	int status;
	money_t amount;
	int currencyId;
  int qty;
} CimEvent;

/** Tipos de archivos que maneja el SafeBox */
typedef enum {
	SafeBoxFileType_RANDOM,
	SafeBoxFileType_CIRCULAR
} SafeBoxFileType;

/** Estado del archivo que maneja el SafeBox */
typedef struct {
	int unitSize;
	SafeBoxFileType fileType;
	unsigned long maxRows;
	unsigned long currentRows;
	unsigned long inIndex;
	unsigned long outIndex;
	unsigned long position;
} SafeBoxFileStatus;


// Eventos de puertas
#define CimEvent_DOOR_OPEN								0
#define CimEvent_DOOR_CLOSE								1

// Eventos de locks
#define CimEvent_LOCK_LOCKED							0
#define CimEvent_LOCK_UNLOCKED  					1

// Eventos del validador
#define CimEvent_BILL_ACCEPTING 					1
#define CimEvent_BILL_REJECTED					  2
#define CimEvent_BILL_ACCEPTED 						3
#define CimEvent_STATUS_CHANGE 						4
#define CimEvent_ACCEPTOR_ERROR 					5
#define CimEvent_SAFE_BOX_ERROR 					8

/**
 *	doc template
 */
@interface SafeBoxHAL : Object
{
  char myLogedUserPersonalId[17]; // mantiene el personal id del usuario logueado
  char myLogedUserPassword[9];    // mantiene la password del usuario logueado
}

+ (void) setEventQueue: (STATIC_SYNC_QUEUE) anEventQueue;

+ (void) start: (int) aComPortNumber;

+ (void) addDevice: (int) aHardwareId deviceType: (DeviceType) aDeviceType object: (id) anObject;

+ (void) setLogedUserPersonalId: (char*) aValue;
+ (void) setLogedUserPassword: (char*) aValue;

+ (char*) getLogedUserPersonalId;

/** MANEJO DEL SAFEBOX **/

+ (HardwareSystemStatus) getHardwareSystemStatus;

+ (BatteryStatus) getBatteryStatus;

+ (PowerStatus) getPowerStatus;

+ (MemoryStatus) getMemoryStatus: (int) aMemoryId;

+ (void) getCimVersion: (char *) aBuffer;

+ (void) shutdown;

/** MANEJO DE VALIDADORES **/

+ (int) setDenomination: (int) aHardwareId amount: (money_t) anAmount disable: (BOOL) aDisable;

+ (int) openBillAcceptor: (int) aHardwareId;

+ (int) closeBillAcceptor: (int) aHardwareId;

+ (int) setValidatedMode: (int) aHardwareId;

+ (BOOL) updateFirmware: (int) aHardwareId path: (char *) aFirmwarePath;

+ (BOOL) updateInnerBoardFirmware: (int) aHardwareId path: (char *) aFirmwarePath;

+ (void) resetBillAcceptors;

+ (void) getBillValidatorVersion: (int) aHardwareId buffer: (char *) aBuffer;

+ (void) setBillAcceptorStatus: (int) aHardwareId enabled: (BOOL) aEnabled;

+ (void) setBillAcceptorCommConfig: (int) aHardwareId acceptorCommConfig: (ValConfig*) anAcceptorCommConfig;

+ (int) getBillAcceptorLastStacked: (int) aHardwareId billAmount: (long long *) aBillAmount currencyId: (int*) aCurrencyId;

/** MANEJO DE PUERTAS **/

+ (int) lock: (int) aHardwareId;

+ (int) unLock: (int) aHardwareId personalId: (char *) aPersonalId password: (char *) aPassword;

+ (int) unLock: (int) aHardwareId personalId1: (char *) aPersonalId1 password1: (char *) aPassword1
	personalId2: (char *) aPersonalId2 password2: (char *) aPassword2;

+ (void) setAutomaticLockTime: (int) aTimeLock1 timeLock2: (int) aTimeLock2 timeLock3: (int) aTimeLock3 timeLock4: (int) aTimeLock4;

+ (void) setUnlockEnableTime: (int) anUnlockEnableTime1 unlockEnable2: (int) anUnlockEnableTime2 unlockEnable3: (int) anUnlockEnableTime3 unlockEnable4: (int) anUnlockEnableTime4;

/** MANEJO DE USUARIOS **/

+ (int) sbAddUser: (unsigned short) aDeviceList 
	personalId: (char *) aPersonalId password: (char *) aPassword duressPassword: (char *) aDuressPassword;

+ (int) sbDeleteUser: (char *) aPersonalId;

+ (int) sbValidateUser: (char *) aPersonalId password: (char *) aPassword;

+ (int) sbChangePassword: (char *) aPersonalId oldPassword: (char *) anOldPassword 
	newPassword: (char *) aNewPassword newDuressPassword: (char *) aNewDuressPassword;

+ (int) sbSetUserDeviceList: (char *) aPersonalId deviceList: (unsigned short) aDeviceList;

+ (int) sbGetUserDeviceList: (char *) aPersonalId;

+ (void) sbSyncFramesQty;

+ (int) sbForceUserPass: (char *) aPersonalId newPassword: (char *) aNewPassword;

+ (int) sbFormatUsers;

/** MANEJO DE ALARMAS **/

+ (int) setAlarm: (int) aHardwareId alarmState: (AlarmState) anAlarmState;

/** MANEJO DE FILE SYSTEM */

/** 
 *	Elimina toda la informacion de la memoria flash, dejandola totalmente vacia 
 */
+ (int) fsBlank;

/**
 *	Crea un archivo en el fileSystem.
 *	@param fileId identificador del archivo.
 *	@param unitSize tamanio del registro.
 *	@param fileType tipo de archivo a crear (circular o random).
 *	@param rows cantidad maxima de registros que pueden existir.
 */
+ (int) fsCreateFile: (int) aFileId unitSize: (int) aUnitSize fileType: (SafeBoxFileType) aFileType rows: (int) aRows;

/**
 *	Lee desde el archivo pasado como parametro.
 *	@param fileId identificador del archivo.
 *	@param numRows cantidad de registros a leer.
 *	@param unitSize tamanio del registro a leer
 *	@param buffer buffer donde se dejaran los datos.
 *	@return cantidad de registros efectivamente leidos.
 */
+ (int) fsRead: (int) aFileId numRows: (int) aNumRows unitSize: (int) aUnitSize buffer: (char *) aBuffer;

/**
 *	Escribe en el archivo pasado como parametro.
 *	@param fileId identificador del archivo.
 *	@param numRows cantidad de registros a leer.
 *	@param unitSize tamnaio del registro.
 *	@param buffer buffer donde se dejaran los datos.
 *	@return cantidad de registros efectivamente leidos.
 */
+ (int) fsWrite: (int) aFileId numRows: (int) aNumRows unitSize: (int) aUnitSize buffer: (char *) aBuffer;

/**
 *  Se posiciona dentro del archivo pasado como parametro.
 *	@param fileId identificador del archivo.
 *	@param offset en cantidad de registros.
 *	@param whence direccion a partir de la cual busca.
 */
+ (int) fsSeek: (int) aFileId offset: (int) anOffset whence: (int) aWhence;

/**
 *	Reinicializa el archivo pasado como parametro, dejandolo en blanco (no lo elimina).
 *	@param fileId identificador del archivo. 
 */
+ (int) fsReInitFile: (int) aFileId;

/**
 *	Obtiene el status del archivo pasado como parametro.
 *	@param fileId identificador del archivo. 
 *	@param status puntero a una estructura del tipo SafeBoxFileStatus donde se devuelve el resultado.
 */
+ (int) fsStatus: (int) aFileId status: (SafeBoxFileStatus*) anStatus;

/**
 *	Obtiene el mutex para el archivo pasado como parametro.
 */
+ (OMUTEX) fsGetMutex: (int) aFileId;

/**
 *  Obtiene TRUE si el fileId pasado como parametro existe, FALSE en caso contrario.
 */
+ (BOOL) fsExists: (int) aFileId;


@end

#endif
