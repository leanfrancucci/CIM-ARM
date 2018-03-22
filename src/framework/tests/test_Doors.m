#include "cut.h"
#include <stdio.h>
#include "AcceptorSettings.h"
#include "Door.h"
#include "test_common.h"

void __CUT_BRINGUP__Door( void )
{
	PRINT_TEST_GROUP("\n** Realizando test de puertas *******************************************\n");
}

void __CUT__Test_Door_Config( void )
{
	DOOR door1 = NULL;
	DOOR door2 = NULL;
	ACCEPTOR_SETTINGS acceptorSettings1 = NULL;
	ACCEPTOR_SETTINGS acceptorSettings2 = NULL;
	ACCEPTOR_SETTINGS acceptorSettings3 = NULL;

	PRINT_TEST("\n    # Probando configuracion de puertas...\n");

	door1 = [Door new];
	[door1 setDoorId: 1];
	ASSERT([door1 getDoorId] == 1, "");
	[door1 setDoorType: DoorType_COLLECTOR];
	ASSERT([door1 getDoorType] == DoorType_COLLECTOR, "");

	door2 = [Door new];
	[door2 setDoorId: 2];
	[door2 setDoorType: DoorType_PERSONAL];

	acceptorSettings1 = [AcceptorSettings new];
	[acceptorSettings1 setAcceptorId: 1];

	acceptorSettings2 = [AcceptorSettings new];
	[acceptorSettings2 setAcceptorId: 2];

	acceptorSettings3 = [AcceptorSettings new];
	[acceptorSettings3 setAcceptorId: 3];

	[door1 addAcceptorSettings: acceptorSettings1];
	[door1 addAcceptorSettings: acceptorSettings1];
	[door1 addAcceptorSettings: acceptorSettings2];

	[door2 addAcceptorSettings: acceptorSettings3];

	ASSERT([acceptorSettings1 getDoor] == door1, "Puerta incorrecta");
	ASSERT([acceptorSettings2 getDoor] == door1, "Puerta incorrecta");
	ASSERT([acceptorSettings3 getDoor] == door2, "Puerta incorrecta");
}

/**/
void __CUT__Test_Door_TimeLock( void )
{
  DOOR door = [Door new];
  TIME_LOCK timeLock;
  datetime_t dt;
  
	PRINT_TEST("\n    # Probando configuracion de Time Locks...\n");
	
	// Lunes de 08 - 10
  timeLock = [TimeLock new];
  [timeLock setDayOfWeek: 1];
  [timeLock setFromMinute: 8 * 60];
  [timeLock setToMinute: 10 * 60];
  [door addTimeLock: timeLock];
  
  // Lun 25/06/07 - 08:45
  dt = [SystemTime encodeTime: 2007 mon: 06 day: 25 hour: 8 min: 45 sec: 30];
  ASSERT([door canOpenDoor: dt], "");
  
  // Lun 25/06/07 - 10:00
  dt = [SystemTime encodeTime: 2007 mon: 06 day: 25 hour: 10 min: 00 sec: 00];
  ASSERT(![door canOpenDoor: dt], "");
  
  // Lun 25/06/07 - 07:45
  dt = [SystemTime encodeTime: 2007 mon: 06 day: 25 hour: 7 min: 45 sec: 30];
  ASSERT(![door canOpenDoor: dt], "");
  
  // Mar 26/06/07 - 08:45
  dt = [SystemTime encodeTime: 2007 mon: 06 day: 26 hour: 8 min: 45 sec: 30];
  ASSERT(![door canOpenDoor: dt], "");  
  
  // Mie 26/06/07 - 08:45
  dt = [SystemTime encodeTime: 2007 mon: 06 day: 27 hour: 8 min: 45 sec: 30];
  ASSERT(![door canOpenDoor: dt], "");  
  
  // Lun 25/06/07 - 22:00
  dt = [SystemTime encodeTime: 2007 mon: 06 day: 25 hour: 22 min: 00 sec: 30];
  ASSERT(![door canOpenDoor: dt], "");
  
  // Lunes de 21:00 - 24:00
  timeLock = [TimeLock new];
  [timeLock setDayOfWeek: 1];
  [timeLock setFromMinute: 21 * 60];
  [timeLock setToMinute: 24 * 60];
  [door addTimeLock: timeLock];

  // Lun 25/06/07 - 22:00
  dt = [SystemTime encodeTime: 2007 mon: 06 day: 25 hour: 22 min: 00 sec: 30];
  ASSERT([door canOpenDoor: dt], "");

  // Lun 25/06/07 - 20:00
  dt = [SystemTime encodeTime: 2007 mon: 06 day: 25 hour: 20 min: 00 sec: 30];
  ASSERT(![door canOpenDoor: dt], "");
  
  // Lun 25/06/07 - 23:59
  dt = [SystemTime encodeTime: 2007 mon: 06 day: 25 hour: 23 min: 59 sec: 59];
  ASSERT([door canOpenDoor: dt], "");
  	
  // Dom 24/06/07 - 23:59
  dt = [SystemTime encodeTime: 2007 mon: 06 day: 24 hour: 23 min: 59 sec: 59];
  ASSERT(![door canOpenDoor: dt], "");
  
  // Dom 24/06/07 - 23:59
  dt = [SystemTime encodeTime: 2007 mon: 06 day: 24 hour: 20 min: 00 sec: 00];
  ASSERT(![door canOpenDoor: dt], "");

  // Domingo de 00:00 - 24:00
  timeLock = [TimeLock new];
  [timeLock setDayOfWeek: 0];
  [timeLock setFromMinute: 0 * 60];
  [timeLock setToMinute: 24 * 60];
  [door addTimeLock: timeLock];

  // Dom 24/06/07 - 00:00    
  dt = [SystemTime encodeTime: 2007 mon: 06 day: 24 hour: 00 min: 00 sec: 00];
  ASSERT([door canOpenDoor: dt], "");
  
  // Dom 24/06/07 - 21:00    
  dt = [SystemTime encodeTime: 2007 mon: 06 day: 24 hour: 00 min: 00 sec: 00];
  ASSERT([door canOpenDoor: dt], "");
  
}

/**/
void __CUT_TAKEDOWN__Door( void )
{
	PRINT_TEST_GROUP("\n** Fin test de puertas *****************************************************\n");
}

