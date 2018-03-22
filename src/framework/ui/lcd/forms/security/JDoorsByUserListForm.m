#include "JDoorsByUserListForm.h"
#include "JDoorsByUserEditForm.h"
#include "UserManager.h"
#include "MessageHandler.h"

#define printd(args...) //doLog(0,args)
//#define printd(args...)

@implementation  JDoorsByUserListForm

/**/
- (void) onConfigureForm
{
	int i = 0;
  USER user;
  PROFILE profile;
  COLLECTION myVisibleUsersList;
  COLLECTION myAuxVisibleUsersList;
  
  myAuxVisibleUsersList = [Collection new];
  
	/**/
	[self setAllowNewInstances: FALSE];
	
	[self setAllowDeleteInstances: FALSE];
	[self setConfirmDeleteInstances: FALSE];
	
	// listo solo los usuarios que tienen el permiso de acceso a puertas	
  myVisibleUsersList = [[UserManager getInstance] getVisibleUsers];
  		
  for (i=0; i<[myVisibleUsersList size];++i) {
		if (![[myVisibleUsersList at: i] isSpecialUser]) {
      user = [myVisibleUsersList at: i];
      profile = [[UserManager getInstance] getProfile: [user getUProfileId]];
      if ([profile hasPermission: OPEN_DOOR_OP])
        [myAuxVisibleUsersList add: user];
    }
  }
    	
	[self addItemsFromCollection: myAuxVisibleUsersList];

	// libera la coleccion
	[myAuxVisibleUsersList free];

}

/**/
- (void) onSelectInstance: (id) anInstance
{
	JFORM form;
	
	form = [JDoorsByUserEditForm createForm: self];
	TRY
		
		[form showFormToView: anInstance];
		
	FINALLY

		[form free];

	END_TRY
}

@end

