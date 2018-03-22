#ifndef  JSECONDARY_USER_LOGIN_FORM_H
#define  JSECONDARY_USER_LOGIN_FORM_H

#define  JSECONDARY_USER_LOGIN_FORM id

#include "UserManager.h"
#include "JCustomForm.h"

#include "JCombo.h"
#include "JLabel.h"
#include "JText.h"

/**
 *
 */
@interface  JSecondaryUserLoginForm: JCustomForm
{
  USER			myUser;

  JLABEL 		myLabelFormDescription;
        
  JLABEL 		myLabelUserName;
  JTEXT 		myTextUserName;
        
  JLABEL 		myLabelUserPassword;
  JTEXT 		myTextUserPassword;
  
  BOOL      myDoLog; // indica si debe o no loguear al usuario
  BOOL	    myCanGoBack;	// indica si el usuario puede ir para atras o no
  BOOL      myIsActive; // indica si el usuario actual esta activo o no
  
  int myCantLoginFails;
  BOOL myValidateLogin;
  char myPersonalId[10];
  char myPassword[10];
  JFORM processForm;

  int forcePasswKey;
        
}

/**/
- (void) doLogFormUser;

/**
 * Devuelve el usuario que logueo el form
 */
- (USER) getLoggedUser;

/**/
- (void) setDoLog: (BOOL) aValue;

/**/
- (void) setCanGoBack: (BOOL) aValue;

/**/
- (void) lockSystem: (int) aSeconds;

/**
 * Setea la variable que indica si se debe ejecutar el login normalmente o no.
 * Cuando se ejecuta la plicacion con hardware secundario se debe setear en FALSE
 */
- (void) setValidateLogin: (BOOL) aValue;

/**
 * Devuelve el personal id ingresado
 */
- (char *) getPersonalId;

/**
 * Devuelve el password ingresado
 */
- (char *) getPassword;

@end

#endif

