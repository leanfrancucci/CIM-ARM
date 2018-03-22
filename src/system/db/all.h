#ifndef DB_ALL_H
#define DB_ALL_H

#include "DBExcepts.h"
#include "AbstractRecordSet.h"
#include "DBConnection.h"

#ifdef CT_SQL_DB

#include "sql/SQLRecordSet.h"
#include "sql/SQLUtils.h"
#include "sql/Transaction.h"

#else

#include "Transaction.h"
#include "rop/Table.h"
#include "rop/RecordSet.h"
#include "rop/MultiPartRecordSet.h"
#include "rop/roputil.h"
#include "rop/DB.h"
#include "rop/TransactionManager.h"

#endif

#endif
