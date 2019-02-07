#include "SafeBoxHAL.h"
#include "system/util/all.h"
#include "CimExcepts.h"
#include "SystemTime.h"
#include "Event.h"
#include "Audit.h"

//#define LOG(args...) doLog(0,args);fflush(stdout)
//#define LOG(args...)

#define COMMAND_TIMEOUT			60000

/**/
typedef struct {
	int fileId;
	OMUTEX mutex;
} FileMutex;

/**/
typedef struct {
	int hardwareId;
	DeviceType deviceType;
	id object;
	STATIC_SYNC_QUEUE syncQueue;
} DeviceMapping;

/**/
typedef struct {
	unsigned char cmd;
	unsigned char rta;
	unsigned char aditData[255];
} SafeBoxResponse;

/**/
static STATIC_SYNC_QUEUE myEventQueue = NULL;
static COLLECTION myDevices = NULL;
static COLLECTION myFileMutexList = NULL;
static OMUTEX myMutex = NULL;
static DeviceMapping *mySafeboxDevice = NULL;

#define CHECK_NULL(device) do { if (device == NULL) return; } while (0)

/**/
void encryptPassword(char *dest, char *password)
{

	char digest[16];
	int lenPassword;
	int i;
 
    printf("encryptPassword sizeof(dest) = %d \n", sizeof dest);
    printf("encryptPassword sizeof(password) = %d \n", sizeof password);
    
    
    printf("password = %s \n", password);
/*	lenPassword = strlen(password);
	if (lenPassword > 8) lenPassword = 8;
  */ 
    memset(dest, 0, 8);
    strcpy(dest, password);

	// Genero el digest md5

//	md5_buffer(password, lenPassword, digest);

//	md5_buffer(password, lenPassword, dest);
	// Me quedo con los primeros 8 digitos del password encriptado
//	memcpy(dest, digest, 8);

/*	printf("MD5 digest for password |%s| = ", password);

	for (i = 0; i < 8; ++i) {
		printf("%02x", dest[i] & 0xFF);
	}

*/
}

/**/
static unsigned char *encodePersonalId(char *dest, char *personalId)
{
	int lenPersonalId;

	memset(dest, 0, 16);
	lenPersonalId = strlen(personalId);
	if (lenPersonalId > 16) lenPersonalId = 16;
	memcpy(dest, personalId, lenPersonalId);
	dest[16] = '\0';

	return dest;
}

@implementation SafeBoxHAL

- (void) firmwareUpdateProgress: (int) aProgress { }

/**/
+ (void) setEventQueue: (STATIC_SYNC_QUEUE) anEventQueue
{
	myEventQueue = anEventQueue;
}

/**/
+ (void) setLogedUserPersonalId: (char*) aValue
{
	stringcpy(myLogedUserPersonalId, aValue);
}

/**/
+ (void) setLogedUserPassword: (char*) aValue
{
	//stringcpy(myLogedUserPassword, aValue);
	encryptPassword(myLogedUserPassword, aValue);
}

/**/
+ (char*) getLogedUserPersonalId
{
	return myLogedUserPersonalId;
}

/**/
DeviceMapping *getDevice(int devId)
{
	int i;
	DeviceMapping *device;

	for (i = 0; i < [myDevices size]; ++i) {
		device = (DeviceMapping *)[myDevices at: i];
		if (device->hardwareId == devId) return device;
	}

			    //************************* logcoment
//	doLog(0,"ERROR: el dispositivo %d no se encuentra mapeado\n", devId);

	return NULL;
}

/**/
void actionCallback(unsigned char devId, unsigned char cmd, unsigned char rta, unsigned char *aditData)
{
	DeviceMapping *device =	getDevice(devId);
	SafeBoxResponse response;

	//printf("SafeBoxHAL -> actionCallback (%d), cmd = %d, rta = %d, aditData[0] = %d, aditData[1] = %d\n", devId, cmd, rta, aditData[0], aditData[1]);
	CHECK_NULL(device);
	
	response.cmd = cmd;
	response.rta = rta;
	memcpy(response.aditData, aditData, sizeof(response.aditData));

	[device->syncQueue pushElement: &response];
}

/**/
void changeAcceptorStatusCallback(unsigned char devId, unsigned char newStatus )
{
	CimEvent event;

	printf("SafeBoxHAL -> changeAcceptorStatusCallback (%d), newStatus = %d\n", devId, newStatus);

	event.hardwareId = devId;
	event.status = newStatus;
	event.event  = CimEvent_STATUS_CHANGE;
	event.amount = 0;

	[myEventQueue pushElement: &event];

}

/**/
void billAcceptingCallback(unsigned char devId, unsigned char newStatus)
{
	CimEvent event;

	//printf("SafeBoxHAL -> accepting... (%d)\n", devId);

	event.hardwareId = devId;
	event.status = newStatus;
	event.event  = CimEvent_BILL_ACCEPTING;
	event.amount = 0;

	[myEventQueue pushElement: &event];
}

/**/
void billRejectedCallback(unsigned char devId, int cause )
{
	CimEvent event;

	//printf("SafeBoxHAL -> billRejectedCallback (%d), %d\n", devId, cause);

	event.hardwareId = devId;
	event.status = cause;
	event.event  = CimEvent_BILL_REJECTED;
	event.amount = 0;
    event.qty = 1;

	[myEventQueue pushElement: &event];
}

/**/
void billAcceptedCallback(unsigned char devId, long long billAmount, int currencyId, int qty)
{
	CimEvent event;
	
	//LOG("SafeBoxHAL -> billAcceptedCallback (%d), %lld, %d\n", devId, billAmount, currencyId);

	event.hardwareId = devId;
	event.status = 0;
	event.event  = CimEvent_BILL_ACCEPTED;
	event.amount = billAmount;
	event.currencyId = currencyId;
  	event.qty = qty;
	[myEventQueue pushElement: &event];

}



/**/
void comunicationErrorCallback(unsigned char devId, int cause )
{
	CimEvent event;
	datetime_t date;
	char dateStr[50];
	char log[150];

	//printf("SafeBoxHAL -> comunicationErrorCallback (%d), cause = %d\n", devId, cause);

    
	if (devId == SAFEBOX) {
	
		strcpy(dateStr, "");	
		date = [SystemTime getGMTTime];
		formatDateTimeComplete(date, dateStr);
//		convertTime(&date, &brokenTime);
//		formatBrokenDate(dateStr, &brokenTime);

        

		if (cause == 0) {
			sprintf(log, "%s - %s\n", dateStr, "RECUPERA CONEXION CON PLACA");
			printf("====================================================\n");
			printf("%s", log);
			printf("====================================================\n");
		}
		else if (cause == 24) {
			// pierde la comunicacion
			sprintf(log, "%s - %s\n", dateStr, "PERDIDA DE CONEXION CON PLACA");
			printf("====================================================\n");
			printf("%s", log);
			printf("====================================================\n");
		}
	}
	else {
		event.hardwareId = devId;
		event.status = cause;
		event.amount = 0;
		event.event  = CimEvent_ACCEPTOR_ERROR;
        
		[myEventQueue pushElement: &event];
	}
}

/**/
void billAcceptingFirmwareUploadCallback(unsigned char devId, unsigned char newStatus)
{
	DeviceMapping *device = getDevice(devId);
	//LOG("SafeBoxHAL -> firmware upload (%d) %d %%)\n", devId, newStatus);
	CHECK_NULL(device);
	[device->object firmwareUpdateProgress: newStatus];
}

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	return self;
}

/**/
+ (void) throwError: (int) anErrorCode
{

	switch (anErrorCode) {
		case ERR_USR_NOT_EXISTS: THROW(CIM_USR_NOT_EXISTS_EX);
		case ERR_USER_EXISTS:  THROW(CIM_USER_EXISTS_EX); 
		case ERR_USR_BAD_PASSWORD:  THROW(CIM_USR_BAD_PASSWORD_EX);
		case ERR_USER_NUM_EXCEEDED: THROW(CIM_USER_NUM_EXCEEDED_EX);
		case ERR_USER_DEVID_NOT_ALLOWED: THROW(CIM_USER_DEVID_NOT_ALLOWED_EX);
		case ERR_USER_COMM_NOT_IN_EMER: THROW(CIM_USER_COMM_NOT_IN_EMER_EX);
		case ERR_FLASH_NOT_REACHABLE: THROW(CIM_FLASH_NOT_REACHABLE_EX);
		case ERR_FLASH_BAD_PROGRAM: THROW(CIM_FLASH_BAD_PROGRAM_EX);
		case ERR_LP_INVALID_CONTENT: THROW(CIM_LP_INVALID_CONTEN_EX);
		case ERR_UNKNOWN_ERROR: THROW(CIM_UNKNOWN_ERROR_EX);
		case ERR_DFILE_INVALID_DF: THROW(CIM_DFILE_INVALID_DF_EX);
		case ERR_DFILE_NOT_ENOUGH: THROW(CIM_DFILE_NOT_ENOUGH_EX);
		case ERR_DFILE_NOT_ALLOWED: THROW(CIM_DFILE_NOT_ALLOWED_EX);
		case ERR_DFILE_BAD_SEEK: THROW(CIM_DFILE_BAD_SEEK_EX);
		case ERR_DFILE_EXISTS_FDESC: THROW(CIM_DFILE_EXISTS_FD_EX);
		case ERR_DFILE_SECTOR_ERROR: THROW(CIM_DFILE_SECTOR_ERROR_EX);
		case ERR_DFILE_NOT_EXISTS: THROW(CIM_DFILE_NOT_EXISTS_EX);
		case ERR_COMMUNICATION_ERROR: THROW(CIM_DFILE_COMMUNICATION_ERROR_EX);
		case ERR_INCOMPATIBLE_FIRMWARE: 
		
						[Audit auditEvent: NULL eventId: Event_INCOMPATIBLE_FIRMWARE_ERROR 
				additional: "" station: 0 logRemoteSystem: FALSE];

		case 26: THROW(CIM_CANNOT_FORMAT_USERS_EX);
	}

	THROW(CIM_UNDEFINED_ERROR_EX);
}

/**/
+ (void) start: (int) aComPortNumber
{
	myMutex = [OMutex new];

	*myLogedUserPersonalId = '\0';
	*myLogedUserPassword = '\0';

	// Agrego el dispositivo SAFEBOX
	[self addDevice: SAFEBOX deviceType: DeviceType_SAFEBOX object: NULL];

	mySafeboxDevice = getDevice(SAFEBOX);

	safeBoxMgrInit(aComPortNumber, 
		changeAcceptorStatusCallback,
		billRejectedCallback,
		billAcceptedCallback, 
		comunicationErrorCallback, 
		billAcceptingCallback, 
		actionCallback);

	// Espera hasta que devuelva algo la version, 
	// con lo cual considero que el sistema arranco
	printf("SafeBoxHAL -> waiting for CIM version...\n");
	while (strlen(safeBoxMgrGetVersion()) == 0) msleep(5);
	printf("SafeBoxHAL -> got version\n");
}

/**/
+ (void) addDevice: (int) aHardwareId deviceType: (DeviceType) aDeviceType object: (id) anObject
{
	DeviceMapping *device;

	if (myDevices == NULL) myDevices = [Collection new];

	device = malloc(sizeof(DeviceMapping));
	device->hardwareId = aHardwareId;
	device->deviceType = aDeviceType;
	device->object = anObject;
	device->syncQueue = [[StaticSyncQueue new] initWithSize: sizeof(SafeBoxResponse) count: 10];

	[myDevices add: device];
}

/**/
+ (int) waitForEvent: (DeviceMapping *) aDevice 
	timeout:  (int) aTimeout 
	response: (SafeBoxResponse *) aSafeBoxReponse
{
	unsigned long ticks = getTicks();

	// Espero por el evento durante el 
	// tiempo de aTimeOut
	while (getTicks() - ticks <= aTimeout) {

		if ([aDevice->syncQueue getCount] > 0) {
			[aDevice->syncQueue popBuffer: aSafeBoxReponse];
			return TRUE;
		}

		msleep(10);
	}

	return FALSE;
}

/**/
+ (int) openBillAcceptor: (int) aHardwareId
{
	printf("SafeBoxHAL -> openBillAcceptor (%d)\n", aHardwareId);
	billAcceptorChangeStatus(aHardwareId, JCM_ENABLE);
	return 1;
}

/**/
+ (int) closeBillAcceptor: (int) aHardwareId
{
	printf("SafeBoxHAL -> closeBillAcceptor (%d)\n", aHardwareId);
	billAcceptorChangeStatus(aHardwareId, JCM_DISABLE);
	return 1;
}

/**/
+ (int) setValidatedMode: (int) aHardwareId
{
	//printf("SafeBoxHAL -> ValidatedMode (%d)\n", aHardwareId);
	billAcceptorChangeStatus(aHardwareId, JCM_VALIDATE_ONLY);
	return 1;
}

/**/
+ (void) setBillAcceptorCommConfig: (int) aHardwareId acceptorCommConfig: (ValConfig*) anAcceptorCommConfig
{
	billAcceptorSetParams(aHardwareId, anAcceptorCommConfig);
}

/**/
+ (int) getBillAcceptorLastStacked: (int) aHardwareId billAmount: (long long *) aBillAmount currencyId: (int*) aCurrencyId
{
	return  getBillAcceptorLastStackedQty( aHardwareId, aBillAmount, aCurrencyId);
 
} 


/**/
+ (int) lock: (int) aHardwareId
{
	//printf("SafeBoxHAL -> lock (%d)\n", aHardwareId);
	safeBoxMgrLock(aHardwareId);
	return 1;
}

/**/
+ (int) setAlarm: (int) aHardwareId alarmState: (AlarmState) anAlarmState
{
			    //************************* logcoment
//	doLog(0,"SafeBoxHAL -> setAlarm (%d) = %d\n", aHardwareId, anAlarmState);
	safeBoxMgrSetAlarm(aHardwareId, anAlarmState);
	return 1;
}

/**/
+ (void) setBillAcceptorStatus: (int) aHardwareId enabled: (BOOL) aEnabled
{
	printf("SafeBoxHAL -> setBillAcceptorStatus (%d) = %d\n", aHardwareId, aEnabled);
	billAcceptorCommunicatStat(aHardwareId, aEnabled);
}


/**/
+ (int) unLock: (int) aHardwareId personalId: (char *) aPersonalId password: (char *) aPassword
{
	return [self unLock: aHardwareId personalId1: aPersonalId password1: aPassword personalId2: NULL password2: NULL];
}

/**/
+ (int) unLock: (int) aHardwareId personalId1: (char *) aPersonalId1 password1: (char *) aPassword1
	personalId2: (char *) aPersonalId2 password2: (char *) aPassword2
{
	SafeBoxResponse response;
	DeviceMapping *device = getDevice(aHardwareId);
	char password1[10];
	char password2[10];
	char personalId1[17];
	char personalId2[17];

	//printf("SafeBoxHAL -> unLock (%d)\n", aHardwareId);

	if (device == NULL) THROW(CIM_DEVICE_NOT_FOUND_EX);

	encodePersonalId(personalId1, aPersonalId1);
	encryptPassword(password1, aPassword1);

	if (aPersonalId2 != NULL) {
		encodePersonalId(personalId2, aPersonalId2);
		encryptPassword(password2, aPassword2);
		safeBoxMgrUnLock(aHardwareId, personalId1, personalId2, password1, password2);
	} else {
		safeBoxMgrUnLock(aHardwareId, personalId1, NULL, password1, NULL);
	}

	if (![SafeBoxHAL waitForEvent: device timeout: COMMAND_TIMEOUT response: &response]) 
		THROW(CIM_COMMAND_TIMEOUT_EX);
	
	//doLog(0,"Recibio la respuesta\n");fflush(stdout);

	if (response.rta == SBOX_FAILURE_CMD) {

			    //************************* logcoment
//		doLog(0,"Failure, aditData = %p\n", response.aditData);

		[SafeBoxHAL throwError: response.aditData[0]];

	} else if (response.rta == SBOX_SUCCESS_CMD) {

		//doLog(0,"Success, aditData = %p\n", response.aditData);
	
		// Si hay usuario 2, me fijo primero que password utilizo
		if (aPersonalId2 != NULL && (response.aditData[1] == 1)) return 0;

		// Coincide con el password normal
		if (response.aditData[0] == 0) return 1;

		// Coincide con el password duress
		if (response.aditData[0] == 1) return 0;
		
	} else {

		THROW(CIM_UNDEFINED_RESPONSE_EX);

	}

	return 0;

}

/**/
+ (int) sbAddUser: (unsigned short) aDeviceList personalId: (char *) aPersonalId 
	password: (char *) aPassword duressPassword: (char *) aDuressPassword
{
	SafeBoxResponse response;
	char password[9];
	char duressPassword[9];

	[myMutex lock];

	TRY
	
		printf("SafeBoxHAL -> sbAddUser, personalId = %s\n", aPersonalId);

		encryptPassword(password, aPassword);

		encryptPassword(duressPassword, aDuressPassword);
		safeBoxMgrAddUsr(aDeviceList, aPersonalId, password, duressPassword, myLogedUserPersonalId, myLogedUserPassword);
	
		if (![SafeBoxHAL waitForEvent: mySafeboxDevice timeout: COMMAND_TIMEOUT response: &response]) 
			THROW(CIM_COMMAND_TIMEOUT_EX);

	FINALLY

		[myMutex unLock];

	END_TRY	

	if (response.rta == SBOX_FAILURE_CMD) {

			    //************************* logcoment
//		doLog(0,"Failure, aditData = %p\n", response.aditData);

		[SafeBoxHAL throwError: response.aditData[0]];

	} else if (response.rta == SBOX_SUCCESS_CMD) {

		return 1;

		
	} else {

		THROW(CIM_UNDEFINED_RESPONSE_EX);

	}

	return 0;

}

/**/
+ (int) sbDeleteUser: (char *) aPersonalId
{
	SafeBoxResponse response;

			    //************************* logcoment
//	doLog(0,"SafeBoxHAL -> delUser, personalId = %s\n", aPersonalId);

	[myMutex lock];

	TRY

		safeBoxMgrDelUsr(aPersonalId, myLogedUserPersonalId, myLogedUserPassword);
	
		if (![SafeBoxHAL waitForEvent: mySafeboxDevice timeout: COMMAND_TIMEOUT response: &response]) 
			THROW(CIM_COMMAND_TIMEOUT_EX);

	FINALLY

		[myMutex unLock];

	END_TRY	
	
	if (response.rta == SBOX_FAILURE_CMD) {

			    //************************* logcoment
//		doLog(0,"Failure, aditData = %p\n", response.aditData);

		[SafeBoxHAL throwError: response.aditData[0]];

	} else if (response.rta == SBOX_SUCCESS_CMD) {

		return 1;
		
	} else {

		THROW(CIM_UNDEFINED_RESPONSE_EX);

	}

	return 0;

}

/**/
+ (int) sbValidateUser: (char *) aPersonalId password: (char *) aPassword
{
	SafeBoxResponse response;
	char password[9];
  char personalId[17];

	[myMutex lock];

	TRY
	
        printf("sbValidateUser \n");
        
        printf("---------sizeof password = %d \n", sizeof(password));
        
		encryptPassword(password, aPassword);
		
		encodePersonalId(personalId, aPersonalId);
		
		//printf("personalId = %s, password = %s \n", personalId, password);
		safeBoxMgrValUsr(personalId, password);

        if (![SafeBoxHAL waitForEvent: mySafeboxDevice timeout: COMMAND_TIMEOUT response: &response]) 
			THROW(CIM_COMMAND_TIMEOUT_EX);

	FINALLY

		[myMutex unLock];

	END_TRY	

	if (response.rta == SBOX_FAILURE_CMD) {

	//	doLog(0,"Failure, aditData = %p, aditData[0] = %d\n", response.aditData, response.aditData[0]);
		[SafeBoxHAL throwError: response.aditData[0]];
	
	} else if (response.rta == SBOX_SUCCESS_CMD) {

			    //************************* logcoment
//		LOG("Success, aditData[0] = %d, aditData[1] = %d, aditData[2] = %d\n", 
	//	response.aditData[0], response.aditData[1], response.aditData[2]);

		// Coincide con el password normal
		if (response.aditData[2] == 0) return 1;

		// Coincide con el password duress
		if (response.aditData[2] == 1) return 0;
		
	} else {

		THROW(CIM_UNDEFINED_RESPONSE_EX);

	}

	return 0;
}

/**/
+ (int) doChangePassword: (char *) aPersonalId oldPassword: (char *) anOldPassword
	newPassword: (char *) aNewPassword passwordType: (int) aPasswordType
{
	SafeBoxResponse response;
	char oldPassword[9];
	char newPassword[9];

	[myMutex lock];

	TRY
        oldPassword[0] = '\0';
        newPassword[9] = '\0';
        
        printf("Llamando a doChangePassword, personalId = %s\n", aPersonalId);
        printf("antes aPersonalId = %s newPassword =%s oldPassword = %s  \n", aPersonalId, aNewPassword, anOldPassword);
    
		encryptPassword(oldPassword, anOldPassword);
		encryptPassword(newPassword, aNewPassword);
	
		
        
        printf("despues aPersonalId = %s newPassword =%s oldPassword = %s  \n", aPersonalId, newPassword, oldPassword);
        
		safeBoxMgrEditUsrPass(aPersonalId, newPassword, oldPassword, aPasswordType);
	
		if (![SafeBoxHAL waitForEvent: mySafeboxDevice timeout: COMMAND_TIMEOUT response: &response]) 
			THROW(CIM_COMMAND_TIMEOUT_EX);

  
	FINALLY

		[myMutex unLock];

	END_TRY	

	if (response.rta == SBOX_FAILURE_CMD) {
			    //************************* logcoment
//		doLog(0,"Failure, aditData = %p, aditData[0] = %d\n", response.aditData, response.aditData[0]);
		[SafeBoxHAL throwError: response.aditData[0]];
	} else if (response.rta == SBOX_SUCCESS_CMD) {
		return 1;
	} else {
		THROW(CIM_UNDEFINED_RESPONSE_EX);
	}

	return 0;
}

/**/
+ (int) sbChangePassword: (char *) aPersonalId oldPassword: (char *) anOldPassword 
	newPassword: (char *) aNewPassword newDuressPassword: (char *) aNewDuressPassword
{
	// En la segunda llamada le paso el NewPassword ya que se supone que lo cambio exitosamente
	// en la primera llamada al metodo
	return ([SafeBoxHAL doChangePassword: aPersonalId oldPassword: anOldPassword newPassword: aNewPassword passwordType: 0] && 
					[SafeBoxHAL doChangePassword: aPersonalId oldPassword: aNewPassword newPassword: aNewDuressPassword passwordType: 1]);
}

/**/
+ (int) sbSetUserDeviceList: (char *) aPersonalId deviceList: (unsigned short) aDeviceList
{
	SafeBoxResponse response;

	[myMutex lock];

	TRY

			    //************************* logcoment
		//doLog(0,"Llamando a sbSetUserDeviceList, personalId = %s, deviceList = %d\n", aPersonalId, aDeviceList);
		safeBoxMgrSetUsrDev(aPersonalId, aDeviceList, myLogedUserPersonalId, myLogedUserPassword);
	
		if (![SafeBoxHAL waitForEvent: mySafeboxDevice timeout: COMMAND_TIMEOUT response: &response]) 
			THROW(CIM_COMMAND_TIMEOUT_EX);

  
	FINALLY

		[myMutex unLock];

	END_TRY	

	if (response.rta == SBOX_FAILURE_CMD) {
//			    //************************* logcoment
//		doLog(0,"Failure, aditData = %p, aditData[0] = %d\n", response.aditData, response.aditData[0]);
		[SafeBoxHAL throwError: response.aditData[0]];
	} else if (response.rta == SBOX_SUCCESS_CMD) {
		return 1;
	} else {
		THROW(CIM_UNDEFINED_RESPONSE_EX);
	}

	return 0;
}

+ (int) sbGetUserDeviceList: (char *) aPersonalId
{
	SafeBoxResponse response;
	unsigned short devList;

	[myMutex lock];

	TRY

			    //************************* logcoment
//		doLog(0,"Llamando a sbGetUserDeviceList, personalId = %s\n", aPersonalId);
		safeBoxMgrGetUsrDev(aPersonalId);
	
		if (![SafeBoxHAL waitForEvent: mySafeboxDevice timeout: COMMAND_TIMEOUT response: &response]) 
			THROW(CIM_COMMAND_TIMEOUT_EX);

	FINALLY

		[myMutex unLock];

	END_TRY	

	if (response.rta == SBOX_FAILURE_CMD) {
			    //************************* logcoment
//		doLog(0,"Failure, aditData = %p, aditData[0] = %d\n", response.aditData, response.aditData[0]);
		[SafeBoxHAL throwError: response.aditData[0]];
	} else if (response.rta == SBOX_SUCCESS_CMD) {
		devList = *((unsigned short*)response.aditData);
		return devList;
	} else {
		THROW(CIM_UNDEFINED_RESPONSE_EX);
	}

	return 0;
}


/**/
+ (void) sbSyncFramesQty
{
			    //************************* logcoment
//	doLog(0,"SafeBoxHAL -> syncFramesQty\n");
	safeBoxMgrSyncFramesQty();
}

/**/
+ (int) sbForceUserPass: (char *) aPersonalId newPassword: (char *) aNewPassword
{
	SafeBoxResponse response;
	char password[10];
	char personalId[17];

			    //************************* logcoment
//	doLog(0,"SafeBoxHAL -> forceUserPass, personalId = %s\n", aPersonalId);

	[myMutex lock];

	TRY
		encodePersonalId(personalId, aPersonalId);
		encryptPassword(password, aNewPassword);
		safeBoxMgrForceUserPass(personalId, password);
	
		if (![SafeBoxHAL waitForEvent: mySafeboxDevice timeout: COMMAND_TIMEOUT response: &response]) 
			THROW(CIM_COMMAND_TIMEOUT_EX);

	FINALLY

		[myMutex unLock];

	END_TRY	
	
	if (response.rta == SBOX_FAILURE_CMD) {

			    //************************* logcoment
//		doLog(0,"Failure, aditData = %p\n", response.aditData);

		[SafeBoxHAL throwError: response.aditData[0]];

	} else if (response.rta == SBOX_SUCCESS_CMD) {

		return 1;
		
	} else {

		THROW(CIM_UNDEFINED_RESPONSE_EX);

	}

	return 0;

}


/**/
+ (void) getBillValidatorVersion: (int) aHardwareId buffer: (char *) aBuffer
{
	strcpy(aBuffer, billAcceptorGetVersion(aHardwareId));
}

+ (void) getCimVersion: (char *) aBuffer
{
	strcpy(aBuffer, safeBoxMgrGetVersion());
}

/**/
+ (int) setDenomination: (int) aHardwareId amount: (money_t) anAmount disable: (BOOL) aDisable
{
	billAcceptorSetDenomination(aHardwareId, anAmount, aDisable);
	return 1;
}

/**/
+ (HardwareSystemStatus) getHardwareSystemStatus
{
	return safeBoxMgrGetSystemStatus();
}

/**/
+ (BatteryStatus) getBatteryStatus
{
	return safeBoxMgrGetBatteryStatus();
}

/**/
+ (PowerStatus) getPowerStatus
{
	return safeBoxMgrGetPowerStatus();
}

/**/
+ (MemoryStatus) getMemoryStatus: (int) aMemoryId
{
	return safeBoxMgrGetMemStatus(aMemoryId);
}

/**/
+ (void) shutdown
{
	[myMutex lock];
			    //************************* logcoment
//	doLog(0,"SafeBoxHAL -> shutdown\n");
	safeBoxMgrShutdown();

	while(1) {

		msleep(10000);

		// reinicio el sistema operativo
		system("reboot");

	}

	[myMutex unLock];
}

/**/
+ (void) setAutomaticLockTime: (int) aTimeLock1 timeLock2: (int) aTimeLock2 timeLock3: (int) aTimeLock3 timeLock4: (int) aTimeLock4
{
	//LOG("SafeBoxHAL -> setAutomaticLockTime %d, %d\n", aTimeLock1, aTimeLock2);
	safeBoxMgrSetTimeLock(aTimeLock1, aTimeLock2, aTimeLock3, aTimeLock4);
}

/**/
+ (void) setUnlockEnableTime: (int) anUnlockEnableTime1 unlockEnable2: (int) anUnlockEnableTime2 unlockEnable3: (int) anUnlockEnableTime3 unlockEnable4: (int) anUnlockEnableTime4
{
	[myMutex lock];

	TRY

		safeBoxMgrSetTimeUnLockEnable(anUnlockEnableTime1, anUnlockEnableTime2, anUnlockEnableTime3, anUnlockEnableTime4);
		
	FINALLY

		[myMutex unLock];

	END_TRY	
}


/**/
+ (BOOL) updateFirmware: (int) aHardwareId path: (char *) aFirmwarePath
{
	return safeBoxMgrUpdateFirmware(aHardwareId, aFirmwarePath, billAcceptingFirmwareUploadCallback);
	
}

/**/
+ (BOOL) updateInnerBoardFirmware: (int) aHardwareId path: (char *) aFirmwarePath
{
	return safeBoxMgrUpdateFirmware(aHardwareId, aFirmwarePath, NULL);

}

/**/
+ (void) resetBillAcceptors
{
	billAcceptorsEnableReset();
}

/**/
+ (int) waitForResponse: (unsigned long) aTimeout
{
	SafeBoxResponse response;

	if (![SafeBoxHAL waitForEvent: mySafeboxDevice timeout: aTimeout response: &response])
		THROW(CIM_COMMAND_TIMEOUT_EX);

	if (response.rta == SBOX_FAILURE_CMD) {
		[SafeBoxHAL throwError: response.aditData[0]];
	} else if (response.rta == SBOX_SUCCESS_CMD) {
		return *response.aditData;
	} else {
		THROW(CIM_UNDEFINED_RESPONSE_EX);
	}

	return 0;
}

/**/
+ (int) waitForData: (char *) aBuffer maxSize: (int) aMaxSize
{
	SafeBoxResponse response;
	int count = 0;

	if (![SafeBoxHAL waitForEvent: mySafeboxDevice timeout: COMMAND_TIMEOUT response: &response]) 
		THROW(CIM_COMMAND_TIMEOUT_EX);

	if (response.rta == SBOX_FAILURE_CMD) {
		[SafeBoxHAL throwError: response.aditData[0]];
	} else if (response.rta == SBOX_SUCCESS_CMD) {
		count = response.aditData[0];
		memcpy(aBuffer, &response.aditData[1], aMaxSize);
	} else {
		THROW(CIM_UNDEFINED_RESPONSE_EX);
	}

	return count;
}

/**/
+ (int) sbFormatUsers
{
	[myMutex lock];

	TRY
	
			    //************************* logcoment
		printf("************************************************SafeBoxHAL -> sbFormatUsers\n");
	
		safeBoxMgrFormatUsrs();
		[SafeBoxHAL waitForResponse: 60 * 5 * 1000];
  
	FINALLY

		[myMutex unLock];

	END_TRY	

	return 1;
}

/// MANEJO DE ARCHIVOS /////////////////////////////////////////////////

/**/
+ (int) fsBlank
{
	[myMutex lock];

	TRY
	
			    //************************* logcoment
//		doLog(0,"SafeBoxHAL -> fsBlank\n");
	
		safeBoxMgrFsBlank();
		[SafeBoxHAL waitForResponse: 60 * 5 * 1000];
  
	FINALLY

		[myMutex unLock];

	END_TRY	

	return 1;
}

/**/
+ (int) fsCreateFile: (int) aFileId unitSize: (int) aUnitSize fileType: (SafeBoxFileType) aFileType rows: (int) aRows
{
	[myMutex lock];

	TRY

	
					    //************************* logcoment
//doLog(0,"SafeBoxHAL -> fsCreateFile, fileId = %d | unitSize = %d | fileType = %d | aRows = %d\n", aFileId, aUnitSize, aFileType, aRows);
	
		safeBoxMgrFSCreateFile(aFileId, aUnitSize, aFileType, aRows);
		[SafeBoxHAL waitForResponse: 60 * 5 * 1000];
  
	FINALLY

		[myMutex unLock];

	END_TRY	

	return 1;
}

/**/
+ (int) fsRead: (int) aFileId numRows: (int) aNumRows unitSize: (int) aUnitSize buffer: (char *) aBuffer
{
	int n = 0;
	int left;
	int nRead;
	int nToRead;

	[myMutex lock];

	TRY

		//LOG("SafeBoxHAL -> fsRead, fileId = %d | aRows = %d | aUnitSize = %d | total = %d\n", aFileId, aNumRows, aUnitSize, aNumRows * aUnitSize);
	
		// Lee tantas veces como haga falta hasta que termine de leer todo el contenido
		// Normalmente va a ser solo una unica vez, pero para archivos de configuracion con tamanio de registro
		// mas grande puede se mas veces
		// Esta rutina solo funciona bien cuando tiene que dividir la lectura en varias
		// solo si el UnitSize = 1, no esta pensada para otra cosa

		nRead = 0;
		left = aNumRows;

		while (left > 0) {

			if (left > MAX_DATA_SIZE) nToRead = MAX_DATA_SIZE;
			else nToRead = left;

			safeBoxMgrFSRead(aFileId, nToRead);
			n += [SafeBoxHAL waitForData: &aBuffer[nRead] maxSize: nToRead * aUnitSize];

			left -= nToRead;
			nRead += nToRead;

		}

	FINALLY

		[myMutex unLock];

	END_TRY	

	return n;
}

/**/
+ (int) fsWrite: (int) aFileId numRows: (int) aNumRows unitSize: (int) aUnitSize buffer: (char *) aBuffer
{
	int n = 0;
	int left;
	int nWrite;
	int nToWrite;

	[myMutex lock];

	TRY

		//LOG("SafeBoxHAL -> fsWrite %d | numRows = %d, unitSize = %d\n", aFileId, aNumRows, aUnitSize);

		left = aNumRows;
		nWrite = 0;

		// Escribe tantas veces como haga falta hasta que termine de escribir todo el contenido
		// Normalmente va a ser solo una unica vez, pero para archivos de configuracion con tamanio de registro
		// mas grande puede se mas veces
		// Esta rutina solo funciona bien cuando tiene que dividir la escritura en varias
		// solo si el UnitSize = 1, no esta pensada para otra cosa

		while (left > 0) {

			if (left > MAX_DATA_SIZE) nToWrite = MAX_DATA_SIZE;
			else nToWrite = left;

			safeBoxMgrFSWrite(aFileId, nToWrite, aUnitSize, &aBuffer[nWrite]);
			n += [SafeBoxHAL waitForResponse: COMMAND_TIMEOUT];

			left -= nToWrite;
			nWrite += nToWrite;

		}

	FINALLY

		[myMutex unLock];

	END_TRY	

	return n;
}

/**/
+ (int) fsSeek: (int) aFileId offset: (int) anOffset whence: (int) aWhence
{
	[myMutex lock];

	TRY

		//LOG("SafeBoxHAL -> fsSeek, fileId = %d | offset = %d | whence = %d\n", aFileId, anOffset, aWhence);
		safeBoxMgrFSSeek(aFileId, anOffset, aWhence);
		[SafeBoxHAL waitForResponse: COMMAND_TIMEOUT];
  
	FINALLY

		[myMutex unLock];

	END_TRY	

	return 1;
}

/**/
+ (int) fsReInitFile: (int) aFileId
{
	[myMutex lock];

	TRY

			    //************************* logcoment
//		doLog(0,"SafeBoxHAL -> fsReInitFile %d\n", aFileId);
		safeBoxMgrFSReInitFile(aFileId);
		[SafeBoxHAL waitForResponse: 60 * 5 * 1000];
  
	FINALLY

		[myMutex unLock];

	END_TRY	

	return 1;
}

/**/
+ (int) fsStatus: (int) aFileId status: (SafeBoxFileStatus*) anStatus
{
	SafeBoxResponse response;

	[myMutex lock];

	TRY


		//LOG("SafeBoxHAL -> fsStatus %d\n", aFileId);
	
		safeBoxMgrFSStatusFile(aFileId);
	
		if (![SafeBoxHAL waitForEvent: mySafeboxDevice timeout: COMMAND_TIMEOUT response: &response])
			THROW(CIM_COMMAND_TIMEOUT_EX);
	
  
	FINALLY

		[myMutex unLock];

	END_TRY	

	if (response.rta == SBOX_FAILURE_CMD) {
		[SafeBoxHAL throwError: response.aditData[0]];
	} else if (response.rta == SBOX_SUCCESS_CMD) {

		anStatus->unitSize =  (unsigned char)*response.aditData;
		anStatus->fileType =  (unsigned char)*(response.aditData+1);
		anStatus->maxRows  = B_ENDIAN_TO_LONG(*(unsigned long *)(response.aditData + 2));
		anStatus->inIndex  = B_ENDIAN_TO_LONG(*(unsigned long *)(response.aditData + 10));
		anStatus->outIndex = B_ENDIAN_TO_LONG(*(unsigned long *)(response.aditData + 6));
		anStatus->currentRows = B_ENDIAN_TO_LONG(*(unsigned long *)(response.aditData + 14));
		anStatus->position = B_ENDIAN_TO_LONG(*(unsigned long *)(response.aditData + 18));

		return 1;


	} else {
		THROW(CIM_UNDEFINED_RESPONSE_EX);
	}

	return 0;
	
}

/**/
+ (BOOL) fsExists: (int) aFileId
{
  SafeBoxFileStatus status;
  BOOL exists = TRUE;

  TRY
    [SafeBoxHAL fsStatus: aFileId status: &status];
  CATCH
    if (ex_get_code() == CIM_DFILE_INVALID_DF_EX || ex_get_code() == CIM_DFILE_NOT_EXISTS_EX )
      exists = FALSE;
    else RETHROW();
  END_TRY

  return exists;
}

/**/
+ (OMUTEX) fsGetMutex: (int) aFileId
{
	int i;
	FileMutex *fm;

	if (myFileMutexList == NULL) {
		myFileMutexList = [Collection new];
	}

	for (i = 0; i < [myFileMutexList size]; ++i) {
		fm = (FileMutex *)[myFileMutexList at: i];
		if (fm->fileId == aFileId) {
			//LOG("SafeBoxHAL -> Devuelve el mutex para el archivo %d\n", fm->fileId);
			return fm->mutex;
		}

	}

	fm = malloc(sizeof(FileMutex));
	fm->fileId = aFileId;
	fm->mutex = [OMutex new];

	//LOG("SafeBoxHAL -> Crea el mutex para el archivo %d\n", fm->fileId);

	[myFileMutexList add: fm];

	return fm->mutex;
}

@end
