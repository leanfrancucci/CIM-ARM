#include "CtSystem.h"
#include "Audit.h"
#include "UserManager.h"
#include "TelesupScheduler.h"
#include "DummyTelesupViewer.h"

// quitar!!!!!!!!!!
#include "DAOExcepts.h"

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
//	doLog(0,"Exception \'%s\', at %s, line %d, code %d [internal code: %d - %s], msg: %s\n", 
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
		[Audit auditEvent: UNHANDLE_EXCEPTION additional: aux station: 0];
	CATCH
	
	END_TRY


}

void run(id system);

/**/
void atexitHandler(void)
{
 // doLog(0,"Funcion llamada al salir\n");fflush(stdout);
//  exit(100);
}

int main(int argc, char **argv)
{
	id myCTSystem;

	//doLog(0,"Creacion del sistema 2\n"); fflush(stdout);
  
  // Registro un handler para manejar algun posible sigsev
  registerSigsevHandler();
  atexit(atexitHandler);
	
	// Configura el manejador de excepciones por defecto
	ex_set_default_handler(app_ex_handler);

	TRY
	
	fdgdgd
	
		myCTSystem = [CtSystem new];
		[myCTSystem startSystem: NULL];

		// Inicializo las instancias
		[[TelesupScheduler getInstance] setTelesupViewer: [DummyTelesupViewer new]];
    [[TelesupScheduler getInstance] start];


		TRY 

			while (TRUE) msleep(10000);

		CATCH
			
		//	doLog(0,"Ha ocurrido una excepcion grave en el hilo principal.\n");
		//	doLog(0,"La aplicacion se cerrara.\n");
			
			// Llama al manejador de excepciones
			ex_call_default_handler();
		
		END_TRY


	CATCH
	
		//doLog(0,"Ha ocurrido una excepcion grave en el hilo principal.\n");
	//	doLog(0,"La aplicacion se cerrara.\n");
		
		// Llama al manejador de excepciones
		ex_call_default_handler();
	
	END_TRY

	
	return 0;
}

