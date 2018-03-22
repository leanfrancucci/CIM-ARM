#ifndef REPORT_XML_CONSTRUCTOR_H
#define REPORT_XML_CONSTRUCTOR_H

#define REPORT_XML_CONSTRUCTOR id

#include <Object.h>
#include "ctapp.h"
#include "XMLConstructor.h"


/**
 *	
 */
@interface ReportXMLConstructor : XMLConstructor
{

}

/**/ 
- (scew_tree*) buildXML: (id) anEntity entityType: (int) anEntityType isReprint: (BOOL) isReprint varEntity: (void *) aVarEntity;
  
@end

#endif
