#ifndef REPORT_CONTROLLER_H
#define REPORT_CONTROLLER_H

#define REPORT_CONTROLLER id

#include <Object.h>
#include "system/util/all.h"
#include "CimDefs.h"


/**
 *	Es el controller para efectuar una extraccion / apertura de puerta
 *	Maneja adicionalmente la apertura de una puerta interna.
 */
@interface ReportController : Object
{
    id myObserver;
}

/**/

- (void) setObserver: (id) anObserver;
- (void) genOperatorReport: (int) aUserId detailed: (BOOL) aDetailed;
- (void) genEndDay: (BOOL) aPrintOperatorReport;
- (void) genEnrolledUsersReport: (int) aStatus detailed: (BOOL) aDetailed;
- (void) genAuditReport: (datetime_t) aDateFrom dateTo: (datetime_t) aDateTo userId: (int) aUserId cashId: (int) aCashId eventCategoryId: (int) anEventCategoryId detailed:(BOOL) detailed;
- (void) genCashReport: (int) aDoorId cashId: (int) aCashId detailed: (BOOL) aDetailed;
- (void) genXCloseReport;
- (void) genCashReferenceReport: (int) aCashReferenceId detailed: (BOOL) aDetailed;
- (void) genSystemInfoReport: (BOOL) aDetailed;
- (void) genTelesupReport;
- (void) reprintDep: (BOOL) isLast fromId: (long) aFromId toId: (long) aToId;
- (void) reprintExt: (BOOL) isLast fromId: (long) aFromId toId: (long) aToId;
- (void) reprintEndD: (BOOL) isLast fromId: (long) aFromId toId: (long) aToId;
- (void) reprintPartialD: (BOOL) isLast fromId: (long) aFromId toId: (long) aToId;


@end

#endif
