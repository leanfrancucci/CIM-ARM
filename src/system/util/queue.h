#ifndef QUEUE_H

#define QUEUE_H



#include "system/lang/all.h"





/**********************************************************************

* S T R U C T U R E S

**********************************************************************/

typedef struct {

   Int indexFirst;		/** index of the first element in the queue */

   Int indexLast;		/** index of the last element in the queue */ 

   Int maxCount;			/** max number of elements that the queue supports */

   Int count;			/** actual number of elements in the queue */ 

   Int dataSize;			/** size of the elements in the queue. All the elements in a queue have got the same size */

   Char* buf;				/** queue itself. It's real size will be the result of: maxcount * datasize */ 

} Queue;



/**********************************************************************

* P U B L I C    F U N C T I O N S

**********************************************************************/



Queue *qNew( Int dataSize, Int maxCount );

void qFree( Queue **q );

void *qAdd( Queue *q, void* element );

void *qRemove( Queue *q, void *element );

void *qGetElement( Queue *q, void* element );

void *qGetLastElement( Queue *q, void* element );

Bool qIsEmpty( Queue *q );





#endif

