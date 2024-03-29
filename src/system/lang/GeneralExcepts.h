#ifndef GENERAL_EXCEPTS_H
#define GENERAL_EXCEPTS_H

#include "system/os/excepts.h"

#define GENERAL_EXCEPT					0

#define GENERAL_EX							(GENERAL_EXCEPT)							
#define	INVALID_POINTER_EX			(GENERAL_EXCEPT + 1)
#define MAX_LEN_EX							(GENERAL_EXCEPT + 2)
#define BUFFER_OVERFLOW_EX			(GENERAL_EXCEPT + 3)
#define FILE_NOT_FOUND_EX				(GENERAL_EXCEPT + 4)
#define	FEATURE_NOT_IMPLEMENTED_EX		(GENERAL_EXCEPT + 5)
#define	ABSTRACT_METHOD_EX 			(GENERAL_EXCEPT + 6)
#define ARRAY_OVERFLOW_EX			  (GENERAL_EXCEPT + 7)
#define	INDEX_OUT_OF_BOUNDS_EX	(GENERAL_EXCEPT + 8)
#define ELEMENT_NOT_FOUND_IN_COLLECTION_EX (GENERAL_EXCEPT + 9)
#define INVALID_PARAMETER_EX	  (GENERAL_EXCEPT + 10)
#define CLASS_METHODS_ONLY_CLASS_EX  (GENERAL_EXCEPT + 10)

#define THROW_NULL(p) if ((p) == NULL) THROW(INVALID_POINTER_EX)

#endif
