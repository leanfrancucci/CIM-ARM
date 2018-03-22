/*



 Queue's management. It allows adding, deleting and consulting an element in

 a queue, knowing if it's full or if it has elements.

 It's necessary to define the structure which the elements in the queue will

 have .



 PROGRAMMER        : Julian Yerfino

 CREATION DATE     : 12/12/2002

 LAST MODIFICATION : 15/01/2003 - Soledad Oliva



*/



#include <string.h>
#include <stdio.h>
#include "syslang.h"

#include "queue.h"

#include "UtilExcepts.h"
#include <stdlib.h>
#include "log.h"



/*********************************************************************

* P U B L I C  F U N C T I O N S

**********************************************************************/



/*



  DESCRIPTION : Creates a new queue, initializing it.



  ARGUMENTS   : Size of the elements in the queue and the number of

  				  elements it's going to support



	RETURNS		: A pointer to the queue just created



*/

Queue *

qNew( Int dataSize, Int maxCount )

{

   Queue * q;



   q	= ( Queue* ) malloc( sizeof( Queue ) );

   q->indexFirst = 0;

   q->indexLast = 0;

   q->count = 0;

   q->maxCount = maxCount;

   q->dataSize = dataSize;

   q->buf	= ( void * ) malloc( dataSize * maxCount );

   return q;

}



/*



  DESCRIPTION : Deletes a queue, freeing the block of bytes requested on the

                creation of the queue .



  ARGUMENTS   : A pointer to the pointer to the queue to delete. 



*/

void

qFree( Queue **q )

{

   free( (*q)->buf );

   free( *q );

   *q = NULL;

   return;

}



/*



  DESCRIPTION : Inserts an element in the queue.



  ARGUMENTS   : A pointer to the queue where the new element is goint to be inserted. 

								 A pointer to the element to be inserted in the queue



  RETURNS		: A pointer to the element just inserted.



  THROWS      :  # INVALID_POINTER   :  if the pointer to the queue is null

                 # QUEUE_IS_FULL     :  if the queue is full and no more elements

                                      can be placed in it         



  NOTES       : The content of the element is copied to the queue (memcpy)



*/

void *

qAdd( Queue *q, void* element )

{

	if (q == NULL )

		THROWF( INVALID_POINTER_EX );

	else {

		if ( q->count == q->maxCount ) {

		//	doLog(0,"queue is full, count = %d, size = %d\n", q->maxCount, q->dataSize);fflush(stdout);
			THROW( QUEUE_IS_FULL_EX );

			}

		else {



			memcpy( q->buf + ( q->indexLast * q->dataSize ), element, q->dataSize );

			q->count++;

			q->indexLast = ( q->indexLast + 1 ) % q->maxCount;



		}

   }

	return element;

}



/*



  DESCRIPTION : Erases the first element in the queue.



  ARGUMENTS   : The queue from which you want to erase the element



  NOTES       : The content of the fisrt element in the queue is copied to the

                element passed as an argument (memcpy)



  THROWS      :  # INVALID_POINTER   :  if the pointer to the queue is null

                 # QUEUE_IS_EMPTY    :  if the queue is empty and there are no elements

                                      to remove



  RETURNS     : The element that was erased.



*/

void * 

qRemove( Queue *q, void *element )

{

	

	/* If the pointer to the element is NULL, an element is removed from the queue

	 but not retrieved */

	if (element != NULL)

		qGetElement( q, element);

	q->count--;

	q->indexFirst = ( q->indexFirst + 1 ) % q->maxCount;



	return( element );



}



/*



	DESCRIPTION : Takes the first element in the queue and copies it's content

                 to the variable element passes as a argument.



	ARGUMENTS   : The queue and the variable where you want to keep the element



	NOTES       : This function only gets the fisrt element in the queue, but IT

                DOES NOT erase the element from the queue. It's used by qRemove

                for that purpose



	THROWS      : # INVALID_POINTER   :  if the pointer to the queue is null

                # QUEUE_IS_EMPTY    :  if the queue is empty and there are no elements

                                      to remove         

	RETURNS     : The pointer to the variable passed as an argument to keep the

                 element



*/

void * 

qGetElement( Queue *q, void* element )

{

	if ( qIsEmpty(q) )

		THROW( QUEUE_IS_EMPTY_EX );

	else {

      if ( element == NULL )

		 THROW( INVALID_POINTER_EX );

      else

      	memcpy( element, ( q->buf ) + ( q->indexFirst * q->dataSize ) , q->dataSize );

   }

	return( element );

}

/**/
void *qGetLastElement( Queue *q, void* element )
{
	
	if ( qIsEmpty(q) )

		THROW( QUEUE_IS_EMPTY_EX );

	else {

      if ( element == NULL )

		 THROW( INVALID_POINTER_EX );

      else

      	memcpy( element, ( q->buf ) + ( (q->indexLast - 1) * q->dataSize ) , q->dataSize );

   }

	return( element );

}

/*



	DESCRIPTION : Verifies if there are elements in the queue 



	ARGUMENTS   : The queue 



	THROWS      : # INVALID_POINTER   :  if the pointer to the queue is null

                                      to remove         

	RETURNS     : # TRUE : if the queue is empty

					  # FALSE : if the queue has got elements



*/

Bool 

qIsEmpty( Queue *q )

{

	if ( q == NULL )

		THROW( INVALID_POINTER_EX );

	return ( (q)->count == 0 );

}





/*********************************************************************

* T E S T I N G    F U N C T I O N S

**********************************************************************/



#ifdef TEST

#include "cunit.h"



int

testQueue( void )

{

   Queue *q;

   int checkQueueExcept = FALSE;



   int a = 5;

   int b = 2;

   int c = 3;

   int result;



   q = qNew( sizeof ( char * ), 3 );



   qAdd( q, &a );

   qAdd( q, &b );

   qAdd( q, &c );



   TRY

		qAdd( q, &c );

   CATCH

		checkQueueExcept = TRUE;

   END_TRY;



   CHECK( checkQueueExcept, "Exception QUEUE_FULL not thrown" );



   qRemove( q, NULL );

//   check( result != 5, "Error in queue a != 5" );

   qRemove( q, &result );

   CHECK( result == 2, "Error in queue b != 2" );

   qGetElement( q, &result );

   CHECK( result == 3, "Error in queue c != 3" );

   qRemove( q, &result );

   CHECK( result == 3, "Error in queue c != 3" );



   CHECK( qIsEmpty( q ), "Error in queue, not empty" );



   qFree( &q );



	 return ( 1 );



}



#endif



