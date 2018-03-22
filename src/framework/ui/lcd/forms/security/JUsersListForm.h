#ifndef  JUSERS_LIST_FORM_H
#define  JUSERS_LIST_FORM_H

#define  JUSERS_LIST_FORM id

#include "JListForm.h"

#include "JLabel.h"
#include "JText.h"
#include "JList.h"


/**
 *
 */
@interface  JUsersListForm: JListForm
{
  BOOL myCanDelete;
  BOOL myCanUpdate;
}

/**/
- (void) onCreateForm;

/**/
- (void) setCanDelete: (BOOL) aValue;
- (BOOL) getCanDelete;
- (void) setCanUpdate: (BOOL) aValue;
- (BOOL) getCanUpdate;

@end

#endif

