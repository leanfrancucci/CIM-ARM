#include "cut.h"
#include "test_common.h"
#include <stdio.h>
#include "Door.h"
#include "ExtractionWorkflow.h"
#include "Door.h"
#include "mocks/GenericMock.h"
#include "User.h"

static DOOR door = NULL;
static EXTRACTION_WORKFLOW extractionWorkflow = NULL;
static id extractionManager = NULL;
static USER user = NULL;

/**/
void openAndCloseDoor(int state)
{

	[extractionWorkflow onDoorOpen: door];
	ASSERT(strstr([extractionManager getLastMethod], "generateExtraction") != NULL, "No se genero la extraccion");
	ASSERT([extractionWorkflow getCurrentState] == state, "Estado incorrecto");

	// Vuelvo a la normalidad
	[extractionManager resetMock];
	[extractionWorkflow onDoorClose: door]; 
	ASSERT([extractionWorkflow getCurrentState] == OpenDoorStateType_IDLE, "Estado incorrecto");

}

/**/
void __CUT_BRINGUP__ExtractionWorkflow( void )
{
	PRINT_TEST_GROUP("\nRealizando test de flujo de extraccion *******************************************\n");

	// Seteos tiempo grandes asi no me molestan
	door = [Door new];
	[door setDoorId: 1];
	[door setDoorName: "TEST DOOR"];
	[door setDoorType: DoorType_COLLECTOR];
	[door setHasElectronicLock: TRUE];
	[door setHasSensor: TRUE];
	[door setAutomaticLockTime: 2000];
	[door setDelayOpenTime: 2000];
	[door setMaxOpenTime: 2000];
	[door setFireAlarmTime: 2000];
	[door setAccessTime: 2000];

	// Usuario
	user = [User new];
	[user setUserId: 1];

	// ExtractionManager MOCK
	extractionManager = [GenericMock new];
	[extractionManager setMockName: "ExtractionManager"];

	// Flujo de extraccion
	extractionWorkflow = [ExtractionWorkflow new];
	[extractionWorkflow setDoor: door];
	[extractionWorkflow setExtractionManager: extractionManager];

}

/**/
void __CUT__Test_ExtractionWorkflow( void )
{
	ASSERT([extractionWorkflow getCurrentState] == OpenDoorStateType_IDLE, "Estado incorrecto");

	PRINT_TEST("\n    # Probando secuencia de apertura de puertas con TimeDelay...\n");

	// Abro la puerta en todos los estados para ver si me genera la extraccion

// Estado IDLE

	openAndCloseDoor(OpenDoorStateType_OPEN_DOOR_VIOLATION);

// Estado TIME_DELAY

	// Login
	[extractionManager resetMock];
	[extractionWorkflow onLoginUser: user];
	ASSERT([extractionWorkflow getCurrentState] == OpenDoorStateType_TIME_DELAY, "Estado incorrecto");
	ASSERT([extractionWorkflow getTimeLeft] > 1990, "Timer incorrecto");

	openAndCloseDoor(OpenDoorStateType_OPEN_DOOR_VIOLATION);
	
// Estado WAIT_SECOND_LOGIN

	// Login
	[extractionManager resetMock];
	[extractionWorkflow onLoginUser: user];

	// Termino el time delay
	[extractionWorkflow timerExpired];
	ASSERT([extractionWorkflow getCurrentState] == OpenDoorStateType_ACCESS_TIME, "Estado incorrecto");

	// Abro puerta
	openAndCloseDoor(OpenDoorStateType_OPEN_DOOR_VIOLATION);

// Estado WAIT_OPEN_DOOR

	// Login
	[extractionManager resetMock];
	[extractionWorkflow onLoginUser: user];

	// Termino el time delay
	[extractionWorkflow timerExpired];
	ASSERT([extractionWorkflow getCurrentState] == OpenDoorStateType_ACCESS_TIME, "Estado incorrecto");
	
	// Login de segundo usuario
	[extractionWorkflow onLoginUser: user];
	ASSERT([extractionWorkflow getCurrentState] == OpenDoorStateType_WAIT_OPEN_DOOR, "Estado incorrecto");

	// Abro puerta	
	openAndCloseDoor(OpenDoorStateType_WAIT_CLOSE_DOOR);

// Estado WAIT_CLOSE_DOOR_WARNING

	// Login
	[extractionManager resetMock];
	[extractionWorkflow onLoginUser: user];

	// Termino el time delay
	[extractionWorkflow timerExpired];
	ASSERT([extractionWorkflow getCurrentState] == OpenDoorStateType_ACCESS_TIME, "Estado incorrecto");
	
	// Login de segundo usuario
	[extractionWorkflow onLoginUser: user];
	ASSERT([extractionWorkflow getCurrentState] == OpenDoorStateType_WAIT_OPEN_DOOR, "Estado incorrecto");

	// Abro la puerta
	[extractionWorkflow onDoorOpen];
	ASSERT(strstr([extractionManager getLastMethod], "generateExtraction") != NULL, "No se genero la extraccion");

	// Expiro el tiempo de WARNING
	[extractionWorkflow timerExpired];
	ASSERT([extractionWorkflow getCurrentState] == OpenDoorStateType_WAIT_CLOSE_DOOR_WARNING, "Estado incorrecto");

	// Expiro el tiempo de ALARM
	[extractionWorkflow timerExpired];
	ASSERT([extractionWorkflow getCurrentState] == OpenDoorStateType_WAIT_CLOSE_DOOR_ERROR, "Estado incorrecto");

	[extractionWorkflow onDoorClose: door];
	ASSERT([extractionWorkflow getCurrentState] == OpenDoorStateType_IDLE, "Estado incorrecto");

}

/**/
void __CUT__Test_ExtractionWorkflowWithoutTimeDelay( void )
{
	PRINT_TEST("\n    # Probando secuencia de apertura de puertas sin TimeDelay...\n");

	[extractionManager resetMock];
	[door setDelayOpenTime: 0];

	ASSERT([extractionWorkflow getCurrentState] == OpenDoorStateType_IDLE, "Estado incorrecto");

	// Abro la puerta en todos los estados para ver si me genera la extraccion

// Estado IDLE

	openAndCloseDoor(OpenDoorStateType_OPEN_DOOR_VIOLATION);

// Estado IDLE -> WAIT_OPEN_DOOR
	[extractionWorkflow onLoginUser: user];
	ASSERT([extractionWorkflow getCurrentState] == OpenDoorStateType_WAIT_OPEN_DOOR, "Estado incorrecto");

	// Abro puerta	
	openAndCloseDoor(OpenDoorStateType_WAIT_CLOSE_DOOR);

}

/**/
void __CUT_TAKEDOWN__ExtractionWorkflow( void )
{
	PRINT_TEST_GROUP("\nFin Realizando test de flujo de extraccion *******************************************\n");
}

