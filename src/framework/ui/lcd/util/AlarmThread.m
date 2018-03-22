#include "AlarmThread.h"
#include "JExceptionForm.h"
#include "JMessageDialog.h"
#include "JNeedMoreTimeForm.h"
#include "JSimpleTimerForm.h"
#include "TelesupScheduler.h"
#include "Acceptor.h"
#include "CimBackup.h"
#include "POSAcceptor.h"


@implementation AlarmThread

static ALARM_THREAD singleInstance = NULL; 

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}
 
/**/
- initialize
{
	mySyncQueue = [SyncQueue new];
	return self;
}

/**/
+ getInstance
{
  return [self new];
}

/**/
- (void) addAlarm: (char *) anAlarm
{
	Alarm *alarm;

	// solo agrego la alarma si NO hay una supervison al POS
	if (![[POSAcceptor getInstance] isTelesupRunning]) {
		alarm = malloc(sizeof(Alarm));
		alarm->text = strdup(anAlarm);
		alarm->object = NULL;
		alarm->dialogMode = JDialogMode_ASK_OK_MESSAGE;
		[mySyncQueue pushElement: alarm];
	}
}

/**/
- (void) askYesNoQuestion: (char *) anAlarm 
	data: (void*) aData 
	object: (id) anObject
	callback: (char *) aCallback 
{
	Alarm *alarm;

	// solo agrego la alarma si NO hay una supervison al POS
	if (![[POSAcceptor getInstance] isTelesupRunning]) {
		alarm = malloc(sizeof(Alarm));
		alarm->text = strdup(anAlarm);
		alarm->object = anObject;
		alarm->data = aData;
		strcpy(alarm->callback, aCallback);
		alarm->dialogMode = JDialogMode_ASK_YES_NO_MESSAGE;
	
		[mySyncQueue pushElement: alarm];
	}
}

/**/
- (void) setAlarmWait: (BOOL) aValue
{	
	myWait = aValue;
}

/*
 * La politica utilizada para mostrar alarmas es la siguiente:
 * 1) Si NO esta en ejecucion las pantallas JMessageDialog, JExceptionForm, 
 *    JNeedMoreTimeForm y JSimpleTimerForm las alarmas se muetran normalmente sin 
 *    ninguna restriccion.
 * 2) Si esta en ejecucion alguna de las pantallas mencionadas en el punto 1) se
 *    ejecutaran solo los mensajes de tipo JDialogMode_ASK_OK_MESSAGE ya que las de tipo 
 *    JDialogMode_ASK_YES_NO_MESSAGE requiere que el operador decida sobre dicha alarma.
 *	  Una vez que deje de estar en ejecucion las pantallas del punto 1) se seguiran 
 *    procesando el resto de las alarmas normalmente.
 * 3) Si hay alguna supervision en curso no proceso las alarmas, salvo que sea en 
 *    background.
 *
 * De esta manera si se pisara alguna alarma de tipo OK_MESSAGE con otra pantalla
 * no pasaria nada y todo seguir�a funcionando.
 */
- (void) run 
{
	Alarm *alarm = NULL;
	Alarm *alarmAux = NULL;
	JDialogResult dialogResult;
	SEL selector;
	int i;

	myWait = FALSE;

	while (TRUE) {

		TRY

			alarm = [mySyncQueue popElement];

			// mientras halla alguna supervision o algun proceso de backup en curso 
			// no proceso las alarmas
			while ( ([[TelesupScheduler getInstance] inTelesup] && ![[TelesupScheduler getInstance] isInBackground]) || 
						 [[Acceptor getInstance] isTelesupRunning] ||
						 [[POSAcceptor getInstance] isTelesupRunning] ||
						 [[CimBackup getInstance] getCurrentBackupType] != BackupType_UNDEFINED ||
						 [[CimBackup getInstance] inRestore]) {
							msleep(1000);
			}

			if (alarm->dialogMode == JDialogMode_ASK_OK_MESSAGE)
				dialogResult = [JExceptionForm showOkForm: alarm->text];
			else {

				// Este while se agrego para que no se muestre la alarma de Yes No mientras
				// este en ejecucion un JMessageDialog, JExceptionForm, JNeedMoreTimeForm o un 
        // JSimpleTimerForm, que son las pantallas que producen solapamientos y perdida 
				// de control de los botones.
				while ( (myWait) || 
								([JWindow getActiveWindow] != NULL && 
								([[JWindow getActiveWindow] isKindOf: [JMessageDialog class]] || 
								[[JWindow getActiveWindow] isKindOf: [JExceptionForm class]] ||
								[[JWindow getActiveWindow] isKindOf: [JNeedMoreTimeForm class]] ||
								[[JWindow getActiveWindow] isKindOf: [JSimpleTimerForm class]]) )) {

							// me fijo si en la cola hay alguna alarma de tipo 
							// JDialogMode_ASK_OK_MESSAGE que pueda procesar
							i = 0;
							while (i < [mySyncQueue getCount]) {
								alarmAux = [mySyncQueue getElementAt: i];
								if (alarmAux->dialogMode == JDialogMode_ASK_OK_MESSAGE) {
									// vuelvo a agregar la alarma YesNo que ya quite al principio, ya que aun no la proceso
									[mySyncQueue pushElement: alarm];
									alarm = alarmAux;
									// quito la alarma JDialogMode_ASK_OK_MESSAGE leida de la cola ya que la voy a procesar
									[mySyncQueue removeAt: i];
									break;
								}
								i++;
							}

							// si encontre una alarma de tipo JDialogMode_ASK_OK_MESSAGE salgo del 
							// while y la proceso, sino sigo esperando
							if (alarm->dialogMode == JDialogMode_ASK_OK_MESSAGE) break;

							msleep(1000);
				}

				// vuelvo a preguntar por JDialogMode_ASK_OK_MESSAGE por si encontro alguna
				if (alarm->dialogMode == JDialogMode_ASK_OK_MESSAGE)
					dialogResult = [JExceptionForm showOkForm: alarm->text];
				else
					dialogResult = [JExceptionForm showYesNoForm: alarm->text];
			}

			alarm->modalResult = dialogResult;

			if (alarm->object != NULL) {
				selector = [alarm->object findSel: alarm->callback];
				if (selector) {
					[alarm->object perform: selector with: alarm];
				}
			}

		CATCH

			//doLog(0,"Excepcion en el hilo de alarmas...\n");
			ex_printfmt();

		END_TRY

		free(alarm->text);
		free(alarm);

	}

}



@end
