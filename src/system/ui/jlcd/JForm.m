#include <assert.h>

#include "UserInterfaceExcepts.h"
#include "UserInterfaceDefs.h"
#include "JForm.h"
#include "JDialog.h"
#include "util.h"

//#define printd(args...) doLog(args)
#define printd(args...)

/**
 *
 *
 */

@implementation  JForm


/***
 * Metodos Publicos
 */


/**/
- (void) initComponent
{
 [super initComponent];
}


/**/
- free
{	
	return [super free];
}

/**/
+ createForm: (JWINDOW) aParentWindow
{
	 return [self createWindow: aParentWindow];
}

/**/
- (void) setModalResult : (JFormModalResult) aModalResult { myModalResult = aModalResult; }
- (JFormModalResult) getModalResult { return myModalResult; }

/**/
- (void) setCanCloseForm: (BOOL) aValue { myCanCloseForm = aValue; }
- (BOOL) canCloseForm { return myCanCloseForm; }

/**/
- (void) showForm
{
	[self showFormWithModalMode: FALSE];
}

/**/
- (JFormModalResult) showModalForm
{
	myModalResult = JFormModalResult_NONE;

	[self showFormWithModalMode: TRUE];
	
	return myModalResult;
}

/**/
- (void) showFormWithModalMode: (BOOL) aModal
{
	[self openWindowWithModalMode: aModal];
}

/**/
- (void) showDefaultExceptionDialogWithExCode: (int) anExceptionCode
{
	char myExceptionMessage[ JComponent_MAX_LEN + 1 ];
	JDIALOG dialog;
	
	dialog = [JDialog createDialog: self];
	TRY	
		
		snprintf(myExceptionMessage, JComponent_MAX_LEN, "Exception: %d!", anExceptionCode);
		[dialog askOKMessageFrom: self withMessage: myExceptionMessage];
		
	FINALLY		
	
		[dialog free];		
		
	END_TRY;	
}


/**/
- (void) closeForm         
{
	[self closeWindow];
}

/**/
- (void) closeFormWithModalResult: (JFormModalResult) aModalResult
{
	myModalResult = aModalResult;
	[self closeForm];
}


/**/
- (void) onCreateWindow
{
	[super onCreateWindow];	
	[self doCreateForm];	
	[self onCreateForm];
}

/**/
- (void) onDestroyWindow
{
	[super onDestroyWindow];
	[self doDestroyForm];
	[self onDestroyForm];
}


/**/
- (void) onOpenWindow
{
	[super onOpenWindow];
	[self doOpenForm];
	[self onOpenForm];	
}

/**/
- (void) onCloseWindow
{
	[super onCloseWindow];
	[self doCloseForm];
	[self onCloseForm];
}

/**/
- (void) onActivateWindow
{
	[super onActivateWindow];	
	[self onActivateForm];
}

/**/
- (void) onDeactivateWindow
{
	[super onDeactivateWindow];
	[self onDeActivateForm];
}

/**/
- (void) doCreateForm
{	
}

/**/
- (void) doDestroyForm
{
}


/**/
- (void) doOpenForm
{	
}

/**/
- (void) doCloseForm
{
}

/**
 * Los eventos definidos por el Form
 */
 
/**/
- (void) onCreateForm
{
}

/**/
- (void) onDestroyForm
{
}


/**/
- (void) onOpenForm
{
}

/**/
- (void) onCloseForm
{
}

/**/
- (void) onActivateForm
{
}

/**/
- (void) onDeActivateForm
{
}


/**
 * Metodos que delegan el mensaje en la super clase.
 * Asi, permite que subclases de JForm reimplementen estos metodos.
 **/
 
/**/
- (int) getFormComponentCount
{
	return [self getComponentCount];
}

/**/
- (JCOMPONENT) getFormComponentAt: (int) anIndex
{
	return [self getComponentAt: anIndex];
}
 
/**/
- (void) addFormComponent: (JCOMPONENT) aComponent
{
	[self addComponent: aComponent];
}

/**/
- (void) addFormBlanks: (int) aQty
{
	[self addBlanks: aQty];
}

/**/
- (void) addFormEol
{
	[self addEol];
}

/**/
- (void) addFormNewPage
{
	[self addNewPage];
}

/**/
- (void) focusFormComponent: (JCOMPONENT) aComponent
{
	[self focusComponent: aComponent];
}

/**/
- (JCOMPONENT) getFormFocusedComponent
{
	return [self getFormFocusedComponent];
}

/**/
- (void) focusFormFirstComponent
{
	[self focusFirstComponent];
}

/**/
- (void) focusFormNextComponent
{
	[self focusNextComponent];
}

/**/
- (void) focusFormPreviousComponent
{
	[self focusPreviousComponent];
}

/**/
- (void) focusFormFirstComponentInCurrentPage
{
	return [self focusFirstComponentInCurrentPage];
}

/**/
- (int) getFormCurrentPage
{
	return [self getCurrentPage];		
}


@end

