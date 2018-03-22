#include "JForceAdminPasswForm.h"
#include "util.h"
#include "JMessageDialog.h"
#include "MessageHandler.h"
#include "Audit.h"
#include "JSystem.h"
#include "SettingsExcepts.h"
#include "SafeBoxHAL.h"
#include "UserManager.h"
#include "JExceptionForm.h"

#define printd(args...) doLog(0,args)
//#define printd(args...)

@implementation  JForceAdminPasswForm


/**/
- (void) onCreateForm
{

	[super onCreateForm];
	
	// Label Codigo
	myLabelCode = [JLabel new];
	[myLabelCode setCaption: "MOSTRAR CODIGO"];
	[myLabelCode setAutoSize: FALSE];
	[myLabelCode setWidth: 20];
	[self addFormComponent: myLabelCode];

  	[self addFormEol];

	// Label Codigo insertado
	myLabelInsertedCode = [JLabel new];
	[myLabelInsertedCode setCaption: getResourceStringDef(RESID_CODE_INSERTED, "Codigo:")];
	[myLabelInsertedCode setAutoSize: FALSE];
	[myLabelInsertedCode setWidth: strlen(getResourceStringDef(RESID_CODE_INSERTED, "Codigo:"))];
	[self addFormComponent: myLabelInsertedCode];
				
	//Text Codigo Insertado
	myTextInsertedCode = [JText new];
	[myTextInsertedCode setWidth: 13];
	[myTextInsertedCode setHeight: 1];	
	[myTextInsertedCode setMaxLen: 13];
	[myTextInsertedCode setPasswordMode: FALSE];
	[myTextInsertedCode setNumericMode: FALSE];
	[self addFormComponent: myTextInsertedCode];
	
  	[self addFormEol];

	// Label Contrasena
	myLabelUserPassword = [JLabel new];
	[myLabelUserPassword setCaption: getResourceStringDef(RESID_TEMPORAL_PIN, "Clave Temp.:")];
	[myLabelUserPassword setAutoSize: FALSE];
	[myLabelUserPassword setWidth: strlen(getResourceStringDef(RESID_TEMPORAL_PIN, "Clave Temp.:"))];
	[self addFormComponent: myLabelUserPassword];
				
	//Text Contrasena temporal
	myTextUserPassword = [JText new];
	[myTextUserPassword setWidth: 8];
	[myTextUserPassword setHeight: 1];	
	[myTextUserPassword setMaxLen: 8];
	[myTextUserPassword setPasswordMode: TRUE];
	[myTextUserPassword setNumericMode: TRUE];
	[self addFormComponent: myTextUserPassword];
}

/**/
- (char *) getCaption1
{
	return getResourceStringDef(RESID_BACK_KEY, "atras");
}

/**/
- (void) onMenu1ButtonClick
{
	myModalResult = JFormModalResult_CANCEL;
	[self closeForm];
}

/**/
- (char *) getCaption2
{
	return getResourceStringDef(RESID_ACCEPT, "aceptar");
}

/**/
- (void) forcePassw
{
  id user;

  // detengo el timer
  [myTimer stop];
  [myTimer free];

  TRY

    // obtengo el usuario admin (id == 1)
    user = [[UserManager getInstance] getUser: 1];

    // reseteo el password del admin
    [SafeBoxHAL sbForceUserPass: [user getLoginName] newPassword: [myTextUserPassword getText]];

    // pongo el password como temporal para forzarlo a cambiar el password luego del login
    [user setIsTemporaryPassword: TRUE];
    [user applyChanges];
    
    // genero la auditoria
    [Audit auditEvent: NULL eventId: AUDIT_FORCE_ADMIN_PASSW additional: "" station: 0 logRemoteSystem: FALSE];
  
    // cierro el formulario de processing
    [processForm closeProcessForm];
    [processForm free];

    myModalResult = JFormModalResult_OK;
    [self closeForm];

  CATCH
	// cierro el formulario de processing
      	[processForm closeProcessForm];
      	[processForm free];

        ex_printfmt();
						
  END_TRY;
}

/**/
- (void) onMenu2ButtonClick
{
  int randSeconds;

  TRY
  	processForm = [JExceptionForm showProcessForm: getResourceStringDef(RESID_PROCESSING, "Procesando...")];

  	// reseteo la placa
  	[SafeBoxHAL sbSyncFramesQty];

  	// espero un tiempo aleatorio
  	sysRandomize();
  	randSeconds = sysRandom(1, 10);

  	myTimer = [OTimer new];
  	[myTimer initTimer: ONE_SHOT period: randSeconds * 1000 object: self callback: "forcePassw"];
  	[myTimer start];

  CATCH
	// cierro el formulario de processing
      	[processForm closeProcessForm];
      	[processForm free];

        ex_printfmt();
						
  END_TRY;

}

@end

