#ifndef LICENCE_MODULES_DAO_H
#define LICENCE_MODULES_DAO_H

#define LICENCE_MODULES_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"

/**/
@interface LicenceModulesDAO : DataObject
{
}

+ getInstance;
- (void) storeModuleElapsedTime: (id) anObject;


@end

#endif
