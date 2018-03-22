#ifndef BACKUPS_DAO_H
#define BACKUPS_DAO_H

#define BACKUPS_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"

/**
 *	Implementacion de la persistencia del backup.
 *
 *	<<singleton>>
 */
@interface BackupsDAO : DataObject
{
}

+ getInstance;

/**/
- (void) loadById: (unsigned long) anId cimBackup: (id) aCimBackup;

@end

#endif
