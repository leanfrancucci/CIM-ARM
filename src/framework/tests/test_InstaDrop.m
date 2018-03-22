#include "cut.h"
#include <stdio.h>
#include "Deposit.h"
#include "User.h"
#include "CimCash.h"
#include "CimDefs.h"
#include "AcceptorSettings.h"
#include "Currency.h"
#include "InstaDrop.h"
#include "test_common.h"
#include "InstaDropManager.h"

void __CUT_BRINGUP__InstaDrop( void )
{
	PRINT_TEST_GROUP("\n** Realizando test de Insta Drop *******************************************\n");
}

void __CUT__Test_InstaDrop( void )
{
  INSTA_DROP_MANAGER manager;
  USER user1;
  USER user2;
  CIM_CASH cimCash1;
  CIM_CASH cimCash2;
	INSTA_DROP instaDrop;
  int i;
  
  // Creo usuarios de prueba
  user1 = [User new];
  [user1 setUserId: 1];
  
  user2 = [User new];
  [user2 setUserId: 2];
  
  // Creo Cash de prueba
  cimCash1 = [CimCash new];
  cimCash2 = [CimCash new];
  
  manager = [InstaDropManager getInstance];
  
  for (i = 1; i < 10; ++i) {
  
    instaDrop = [manager getInstaDropForKey: i];
    ASSERT([instaDrop isAvaliable], "");
    
  }
      
  [manager setInstaDrop: 1 user: user1 cimCash: cimCash1];
  instaDrop = [manager getInstaDropForKey: 1];
  ASSERT(![instaDrop isAvaliable], "");
  ASSERT([instaDrop getUser] == user1, "");
  ASSERT([instaDrop getCimCash] == cimCash1, "");
  
  [manager setInstaDrop: 5 user: user2 cimCash: cimCash2];
  instaDrop = [manager getInstaDropForKey: 5];
  ASSERT(![instaDrop isAvaliable], "");
  ASSERT([instaDrop getUser] == user2, "");
  ASSERT([instaDrop getCimCash] == cimCash2, "");
  
  [manager clearInstaDrop: 1];
  instaDrop = [manager getInstaDropForKey: 1];
  ASSERT([instaDrop isAvaliable], "");
  
  [manager clearInstaDropByUser: user2];
  instaDrop = [manager getInstaDropForKey: 5];
  ASSERT([instaDrop isAvaliable], "");
 
  for (i = 1; i < 10; ++i) {
  
    instaDrop = [manager getInstaDropForKey: i];
    ASSERT([instaDrop isAvaliable], "");
    
  }
      
  	
}

/**/
void __CUT_TAKEDOWN__InstaDrop( void )
{
	PRINT_TEST_GROUP("\n** Fin test de Insta Drop *****************************************************\n");
}

