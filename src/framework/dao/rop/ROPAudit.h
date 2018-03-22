#ifndef ROP_AUDIT_H
#define ROP_AUDIT_H

#define ROP_AUDIT id

#include <Object.h>
#include "ctapp.h"
#include "rop.h"
#include "DataObject.h"
#include "system/os/all.h"
#include "AuditDAO.h"

/**
 *	Implementacion ROP de la persistencia de eventos de auditoria.
 *	Provee metodos para recuperar un evento de auditoria.
 *
 *	<<singleton>>
 */
@interface ROPAudit : AuditDAO
{
}

@end

#endif
