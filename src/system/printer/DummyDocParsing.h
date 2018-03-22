#ifndef DUMMY_DOC_PARSING_H
#define DUMMY_DOC_PARSING_H

#define DUMMY_DOC_PARSING id

#include <Object.h>
#include "DocParsing.h"

/**
 *	Subclase de DocParsing, que no hace nada y se crea para cuando no se tiene una impresora configurada
 */
@interface DummyDocParsing : DocParsing
{

}


@end

#endif
