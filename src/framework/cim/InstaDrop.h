#ifndef INSTA_DROP_H
#define INSTA_DROP_H

#define INSTA_DROP id

#include <Object.h>
#include "User.h"
#include "CimCash.h"
#include "CashReference.h"

/**
 *	Define un Insta Drop.
 *	Contiene informacion acerca del usuario, el cash y la tecla asociada. 
 */
@interface InstaDrop : Object
{
/** Tecla de funcion utilizada por el usuario al realizar un Insta Drop */
  int myFunctionKey;
  
/** Usuario asociado al Insta Drop */
  USER myUser;
  
/** Cash asociado al Insta Drop */
  CIM_CASH myCimCash;

/** Reference asociado al Insta Drop */
	CASH_REFERENCE myCashReference;
  
/** Buffer para devolver el STR */
  char myBuffer[41];

	char myEnvelopeNumber[50];
	
	char myApplyTo[50];
}

/**/
- (void) clear;

/**/
- (BOOL) isAvaliable;

/**/
- (void) setUser: (USER) aUser;
- (USER) getUser;

/**/
- (void) setCimCash: (CIM_CASH) aCimCash;
- (CIM_CASH) getCimCash;

/**/
- (void) setFunctionKey: (int) aFunctionKey;
- (int) getFunctionKey; 

/**/
- (void) setCashReference: (CASH_REFERENCE) aCashReference;
- (CASH_REFERENCE) getCashReference;

/**/
- (void) setEnvelopeNumber: (char *) anEnvelopeNumber;
- (char *) getEnvelopeNumber;

/**/
- (void) setApplyTo: (char *) anApplyTo;
- (char *) getApplyTo;

@end

#endif
