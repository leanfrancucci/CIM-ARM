#include "CtSystem.h"
#include "JMessageDialog.h"
#include "JExceptionForm.h"
//#include "testEncript.h"
#include "Audit.h"


/**
 *	Manejador de excepciones por defecto de la aplicacion.
 *	Cada vez que ocurre una excepcion no capturada en la aplicacion, se debe llamar a este
 *	manejador de excepciones. Su funcion es:
 *	1) Imprimir la excepcion por consola.
 *	2) Guardala en un archivos de logging (exceptions.log).
 *	3) Guardar una auditoria con el codigo de excepcion.
 *	4) Mostrar un mensaje de error por el display.
 */
void
app_ex_handler(char *name, char*file, int line, int excode, int adcode, 
							 char* admsg, char*msg)
{
	char aux[20];
	
	// La imprimo por pantalla
	doLog(0,"Exception \'%s\', at %s, line %d, code %d [internal code: %d - %s], msg: %s\n", 
			 name,  file, line, excode, adcode, 
			 adcode > 0 ? strerror(adcode): "",
	 		 msg );

	// La guardo en un log
	logToFile("exceptions.log", "Exception \'%s\', at %s, line %d, code %d [internal code: %d - %s], msg: %s\n", 
			 name,  file, line, excode, adcode, 
			 adcode > 0 ? strerror(adcode): "",
	 		 msg );
	
	// Genero la auditoria
	sprintf(aux, "%d", excode);
	TRY
		[Audit auditEvent: UNHANDLE_EXCEPTION additional: aux station: 0 logRemoteSystem: FALSE];
	CATCH
	
	END_TRY
			 
	// La muestro por display
	[JExceptionForm showException: excode exceptionName: name];
	
}

void run(id system);


int main(int argc, char **argv)
{
    
//    id myTimer1;
	id myCTSystem;
	char msg[10];

	initLog();

 
#ifdef __UCLINUX
	printf("Creacion del sistema UCLINUX1\n"); fflush(stdout);
#endif
    
#ifdef __LINUX
	printf("Creacion del sistema LINUX1\n"); fflush(stdout);
#endif

#ifdef __ARM_LINUX
        printf("Creacion del sistema ARMLINUX\n"); fflush(stdout);
#endif
	
	
   initializeMainThread();
	
	
//	testEncript();
	// Configura el manejador de excepciones por defecto
	ex_set_default_handler(app_ex_handler);

	threadSetPriority(5);
    printf("Inicializando\n");

    
   
	TRY
	
	
        myCTSystem = [CtSystem new];

		run(myCTSystem);

 
	CATCH
	
		printf("Ha ocurrido una excepcion grave en el hilo principal.\n");
		printf("La aplicacion se cerrara.\n");
		
		// Llama al manejador de excepciones
		ex_call_default_handler();
	
	END_TRY
	
	return 0;
}

