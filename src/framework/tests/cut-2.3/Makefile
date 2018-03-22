# CUT 2.2
# Copyright (c) 2001-2003 Samuel A. Falvo II, William Tanksley
# See LICENSE.TXT for details.
#
# $Log: Makefile,v $
# Revision 1.1  2007-05-28 20:12:49  yerfino
# *** empty log message ***
#
# Revision 1.2  2003/03/13 04:27:54  sfalvo
# ADD: LICENSE.TXT -- zlib license
#
# ADD: README cut.h cutgen.c -- Changelog token for CVS
#
# FIX: test/bringup-failure -- reflects new usage for bringups and
# teardowns in CUT 2.2.
#

CC		= gcc

linux: cutgen.c
	$(CC) -D__LINUX__ cutgen.c -o cutgen

clean:
	rm -f *.o *~ cutgen

