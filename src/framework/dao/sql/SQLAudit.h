#ifndef SQL_AUDIT_H
#define SQL_AUDIT_H

#define SQL_AUDIT id

#include <Object.h>
#include "ctapp.h"
#include "AuditDAO.h"
#include "system/os/all.h"

/**
 *	Implementacion SQL de la persistencia de eventos de auditoria.
 *	Provee metodos para recuperar un evento de auditoria.
 *
 *	<<singleton>>
 */
@interface SQLAudit : AuditDAO
{

}


@end

#endif
