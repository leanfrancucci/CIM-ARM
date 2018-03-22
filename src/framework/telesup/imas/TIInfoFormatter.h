#ifndef TI_INFO_FORMATTER_H
#define TI_INFO_FORMATTER_H

#define TI_INFO_FORMATTER id

#include <Object.h>
#include "ctapp.h"
#include "InfoFormatter.h"

/** 
 *
 */
@interface TIInfoFormatter: InfoFormatter
{
	ABSTRACT_RECORDSET myUsersRS;
}


@end

#endif
