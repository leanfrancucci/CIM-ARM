#include "TestThread.h"
#include "system/net/all.h"


@implementation TestThread

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	[super initialize];

	return self;
}

/**/
- (void) setReader: (id) aReader
{
    myReader = aReader;
}

/**/
- (void) run
{
    char *myAuxMessage = malloc(TELESUP_MSG_SIZE + 1);
    char *p = myAuxMessage;
    int excode;
    int myErrorCode = 0 ;
    int size;
    
//	while (1) {

    
    TRY
    
		                msleep(10000);
          //      THROW( TSUP_GENERAL_EX );
                
    CATCH
    
        printf("Excepiob en TestThread 1\n"); 
    //    RETHROW();
    
    END_TRY    
    
   


}

@end
