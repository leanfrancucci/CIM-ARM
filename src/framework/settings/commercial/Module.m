#include "Module.h"
#include "Persistence.h"
#include "util.h"
#include "SystemTime.h"
#include "openssl/sha.h"
#include "openssl/objects.h"
#include "openssl/x509.h"
#include "StringTokenizer.h"
#include "math.h"
#include "MessageHandler.h"
#include "TelesupDefs.h"
#include "SettingsExcepts.h"
#include "Audit.h"
#include "CommercialUtils.h"
#include "LicenceModulesDAO.h"
#include "RegionalSettings.h"
#include "CimGeneralSettings.h"
#include "TelesupervisionManager.h"

@implementation Module

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
  myModuleId = 0;
  myModuleCode = 0;
	myModuleName[0] = '\0';
  myBaseDateTime = 	truncDateTime([SystemTime getGMTTime]);
	myExpireDateTime = truncDateTime([SystemTime getGMTTime]);
	myHoursQty = 0;
	*mySignature = 0;
	*myEncodedRemoteSignature = 0;
  myAuthorizationId = 0;
	memset(myRemoteSignature, 0, 50);
	myElapsedTime = 0;
  myEnable = FALSE;
	myOnline = FALSE;
	signatureCorrect = FALSE;
	return self;
}

/**/
- (void) setModuleId: (int) aValue { myModuleId = aValue; }
- (void) setModuleCode: (int) aValue { myModuleCode = aValue; }
- (void) setBaseDateTime: (datetime_t) aValue { myBaseDateTime = aValue; }
- (void) setExpireDateTime: (datetime_t) aValue { myExpireDateTime = aValue; }
- (void) setHoursQty: (int) aValue { myHoursQty = aValue; }
- (void) setEncodedRemoteSignature: (char*) aValue { stringcpy(myEncodedRemoteSignature, aValue); };
- (void) setRemoteSignatureLen: (int) aValue { myRemoteSignatureLen = aValue; }
- (void) setRemoteSignature: (unsigned char*) aRemoteSignature remoteSignatureLen: (int) aRemoteSignatureLen { memcpy(myRemoteSignature, aRemoteSignature, aRemoteSignatureLen); }
- (void) setAuthorizationId: (unsigned long) aValue { myAuthorizationId = aValue; }
- (void) setElapsedTime: (unsigned long) aValue { myElapsedTime = aValue; }
- (void) setEnable: (BOOL) aValue { myEnable = aValue; }
- (void) setOnline: (BOOL) aValue { myOnline = aValue; }

/**/
- (int) getModuleId { return myModuleId; }
- (int) getModuleCode { return myModuleCode; }
- (datetime_t) getBaseDateTime { return myBaseDateTime; }
- (datetime_t) getExpireDateTime { return myExpireDateTime; }
- (int) getHoursQty { return myHoursQty; }
- (int) getRemoteSignatureLen { return myRemoteSignatureLen; }
- (unsigned char*) getRemoteSignature { return myRemoteSignature; }
- (unsigned long) getAuthorizationId { return myAuthorizationId; }
- (unsigned long) getElapsedTime { return myElapsedTime; }
- (BOOL) isEnable { return myEnable; }
- (BOOL) getOnline { return myOnline; }

/**/
- (char*) getModuleName
{
	stringcpy(myModuleName, getResourceString(RESID_Modules_DSC + myModuleCode));

	return myModuleName;	
}

/**/
- (void) applyChanges
{
	id moduleDAO = [[Persistence getInstance] getLicenceModuleDAO];

	[moduleDAO store: self];

}

/**/
- (void) applyTimeElapsed
{
	id moduleDAO = [[Persistence getInstance] getLicenceModuleDAO];

	[moduleDAO storeModuleElapsedTime: self];
}

/**/
- (BOOL) hasExpired
{
	unsigned long sec; 

	// si se encuentra habilitado y la cantidad de horas es
	// cero entonces quiere decir que no expira nunca.

	if ( (myEnable) && (myHoursQty == 0) ) {
		//doLog(0,"NO expira nunca \n");
		return FALSE;
	}
	
	// si esta habilitado y vencio su periodo por fechas --> gmttime > expiretime o gmttime < basetime 
	if (([SystemTime getGMTTime] > myExpireDateTime) || ([SystemTime getGMTTime] < myBaseDateTime)) {
//   [Audit auditEventCurrentUser: Event_MODULE_EXPIRED_BY_DATE additional: [self getModuleName] station: myModuleCode logRemoteSystem: FALSE]; 			
	 //doLog(0,"vencio por fechas \n");
	 return TRUE;
	}

	sec = myHoursQty * 3600;

	// si esta habilitado y el tiempo de uso es mayor al tiempo brindado
	if (myElapsedTime > sec) {
 //  [Audit auditEventCurrentUser: Event_MODULE_EXPIRED_BY_ELAPSED_TIME additional: [self getModuleName] station: myModuleCode logRemoteSystem: FALSE]; 			
	 //doLog(0,"vencio por tiempo transcurrido \n");
	 return TRUE;
	}

	//doLog(0,"modulo %d no vencio \n", myModuleCode);
	return FALSE;
}

/**/
- (unsigned char*) buildData: (unsigned char*) data
{
	char modCode[5];
	char buf2[] = "0000:00:00T00:00:00+00:00\0\0";		
	char buf3[] = "0000:00:00T00:00:00+00:00\0\0";		
	char expireDateTime[40];
	char baseDateTime[40];
	id telesup;
	char pimsId[40];
	char mac[50];
	
	sprintf(modCode, "%d", myModuleCode);

	sprintf(baseDateTime, "%s", datetimeToISO8106(buf3, myBaseDateTime));
	sprintf(expireDateTime, "%s", datetimeToISO8106(buf2, myExpireDateTime));

	telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];
	
	if (!telesup) stringcpy(pimsId, "0");
	else stringcpy(pimsId, [telesup getRemoteSystemId]);

/*	doLog(0,"Build module data\n");
	doLog(0,"PimsId = %s\n", pimsId);
	doLog(0,"Macaddress = %s \n",  [[CimGeneralSettings getInstance] getMacAddress: mac]);
	doLog(0,"Module code = %s\n", modCode);
	doLog(0,"Base date time = %s\n", baseDateTime);
	doLog(0,"Expire date time = %s\n", expireDateTime);
	doLog(0,"Hours qty = %d\n", myHoursQty);
	doLog(0,"Online = %d\n", myOnline);
	doLog(0,"IsEnable = %d\n", myEnable);
	doLog(0,"AuthorizationId = %ld\n", myAuthorizationId);
*/
	sprintf(data, "%s%s%s%s%s%d%d%d%ld", pimsId,  [[CimGeneralSettings getInstance] getMacAddress: mac], modCode, baseDateTime, expireDateTime, myHoursQty, myOnline, myEnable, myAuthorizationId);

	return data;

}

/**/
- (BOOL) canBeExecuted
{
	// no verifica que este habilitado porque puede ser que este inhabilitado pero no ha vencido
 // aun su periodo.

	if ( (![self hasExpired]) &&  (signatureCorrect) ) return TRUE;
	
	return FALSE;

}

/**/
- (void) updateTimeElapsed: (unsigned long) anElapsedTime
{
	myElapsedTime += anElapsedTime;
	[self applyTimeElapsed];
}

/***********************************************************/
/*    DEBUG 																							 */
/***********************************************************/

/**/
- (void) printInfo
{
	
  datetime_t date;
	char dateStr[50];
  struct tm brokenTime;

/*	doLog(0,"*******************************************\n");
	doLog(0,"Info module %s \n", [self getModuleName]);
	doLog(0,"*******************************************\n");
	doLog(0,"Module id %d \n", [self getModuleId]);	
	doLog(0,"Module code %d \n", [self getModuleCode]);
*/
	date = [self getBaseDateTime];
	localtime_r(&date, &brokenTime);
	strftime(dateStr, 50, [[RegionalSettings getInstance] getDateTimeFormatString], &brokenTime);
	//doLog(0,"Module base date time %s \n", dateStr);	

	date = [self getExpireDateTime];
	localtime_r(&date, &brokenTime);
	strftime(dateStr, 50, [[RegionalSettings getInstance] getDateTimeFormatString], &brokenTime);
//	doLog(0,"Module expire date time %s \n", dateStr);	

	//doLog(0,"Module hours %d \n", [self getHoursQty]);

	//doLog(0,"Module authorizationId  %ld \n", [self getAuthorizationId]);

//	doLog(0,"Module elapsed time %ld \n", [self getElapsedTime]);

	/*if ([self getOnline])
		doLog(0,"Module online YES \n");
	else
		doLog(0,"Module online NO \n");*/

    printf("13\n");
/*	if ([self isEnable])
		doLog(0,"Module enable YES \n");
	else
		doLog(0,"Module enable NO \n");

*/
}

/**/
- (void) setSignatureVerification: (DSA*) dsa
{
	char data[200];
	int result;

//	doLog(0,"SetSignatureVerification\n");

	// solo verifica si esta habilitado y no expiro

	if ((myEnable) && (![self hasExpired])) {

		[self buildData: data];
	
		result = [CommercialUtils verifySignature: dsa data: data signature: myRemoteSignature signatureLen: myRemoteSignatureLen];
	
		if (result == 0) {
		//	doLog(0,"error en firma\n");
			[Audit auditEventCurrentUser: Event_MODULE_SIGNATURE_VERIFICATION_ERROR additional: [self getModuleName] station: myModuleCode logRemoteSystem: FALSE]; 		
			signatureCorrect = FALSE;
		} else signatureCorrect = TRUE;

	}
}
 
@end

