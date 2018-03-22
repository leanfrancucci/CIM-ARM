#ifndef  JTELESUP_TYPES_LIST_FORM_H
#define  JTELESUP_TYPES_LIST_FORM_H

#define  JTELESUP_TYPES_LIST_FORM id

#include "JListForm.h"


/**
 *
 */
@interface  JTelesupTypesListForm: JListForm
{
	int mySelectedTelesupType;
}


- (int) getSelectedTelesupType;

@end

#endif

