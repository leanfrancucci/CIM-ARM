#ifndef MODULE_H
#define MODULE_H

#define MODULE id

#include "Object.h"
#include "ctapp.h"
#include "openssl/dsa.h"


typedef enum {
	ModuleCode_NOT_DEFINED, 	    //0
	ModuleCode_SEND_AUDITS,				//1
	ModuleCode_SEND_DROPS,		    //2
	ModuleCode_SEND_EXTRACTIONS,	//3
	ModuleCode_SEND_END_OF_DAY,		//4
	ModuleCode_SOFTWARE_UPDATE,		//5
  ModuleCode_VALIDATORS_UPDATE, //6
  ModuleCode_SEND_ALARMS,       //7
  ModuleCode_USER_SETTINGS,     //8
  ModuleCode_SETTINGS,  				//9
  ModuleCode_WORK_ORDER, 				//10
	ModuleCode_CDM3000_PROTOCOL,	//11
	ModuleCode_ADB_SUPERVISION		//12
} ModuleCode;

/**
 * Clase  
 */

@interface Module:  Object
{
	int myModuleId;
  int myModuleCode;
	char myModuleName[50];
  datetime_t myBaseDateTime;
	datetime_t myExpireDateTime;
	int myHoursQty;
	BOOL myOnline;
	char mySignature[200];
	char myEncodedRemoteSignature[200];
	unsigned char myRemoteSignature[50];
	int myRemoteSignatureLen;
  unsigned long myAuthorizationId;
	unsigned long myElapsedTime;
	BOOL myEnable;
	BOOL signatureCorrect;
}

/**
 * 
 */
- initialize;
				
/**
 * 
 */
- (void) setModuleId: (int) aValue;
- (void) setModuleCode: (int) aValue;
- (void) setBaseDateTime: (datetime_t) aValue;
- (void) setExpireDateTime: (datetime_t) aValue;
- (void) setHoursQty: (int) aValue;
- (void) setOnline: (BOOL) aValue;
- (void) setEncodedRemoteSignature: (char*) aValue;
- (void) setRemoteSignatureLen: (int) aValue;
- (void) setRemoteSignature: (unsigned char*) aRemoteSignature remoteSignatureLen: (int) aRemoteSignatureLen;
- (void) setAuthorizationId: (unsigned long) aValue;
- (void) setElapsedTime: (unsigned long) aValue;
- (void) setEnable: (BOOL) aValue;

/**
 * 
 */
- (int) getModuleId;
- (char*) getModuleName;
- (int) getModuleCode;
- (datetime_t) getBaseDateTime;
- (datetime_t) getExpireDateTime;
- (int) getHoursQty;
- (BOOL) getOnline;
- (unsigned char*) getRemoteSignature;
- (int) getRemoteSignatureLen;
- (unsigned long) getAuthorizationId;
- (unsigned long) getElapsedTime;
- (BOOL) isEnable;

/**
 * Aplica los cambios realizados sobre la instancia correspondiente al modulo
 */	
- (void) applyChanges;

/**
 * Aplica los cambios realizados al tiempo transcurrido del modulo.
 */
- (void) applyTimeElapsed;

/**
 *
 */
- (BOOL)hasExpired;

/**
 *
 */
- (BOOL) canBeExecuted;

/**
 *
 */
- (void) updateTimeElapsed: (unsigned long) anElapsedTime;

/**/
- (void) printInfo;

/**/
- (void) setSignatureVerification: (DSA*) dsa;

@end

#endif

