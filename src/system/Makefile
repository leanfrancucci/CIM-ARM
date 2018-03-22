
.PHONY: clean all db io net os util dev ui scew expat printer

LDFLAGS=-L/lib

TARGET: all

db:
	make -s -f db/Makefile

io:
	make -s -f io/Makefile
	
net:
	make -s -f net/Makefile 

os:
	make -s -f os/Makefile
	
util:
	make -s -f util/Makefile
	
dev:
	make -s -f dev/Makefile

ui:
	make -s -f ui/Makefile

scew:
	make -s -f scew/Makefile

expat:
	make -s -f expat/Makefile
	
printer:
	make -s -f printer/Makefile

all: db io net os util dev ui scew expat printer
	

clean: 
	rm -f *.o *.d 2> /dev/null
	make clean -f db/Makefile
	make clean -f io/Makefile
	make clean -f net/Makefile
	make clean -f os/Makefile
	make clean -f util/Makefile
	make clean -f dev/Makefile
	make clean -f ui/Makefile	
	make clean -f scew/Makefile	
	make clean -f expat/Makefile	
	make clean -f printer/Makefile	  
	
