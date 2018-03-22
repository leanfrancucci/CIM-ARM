/* Automatically generated: DO NOT MODIFY. */
/*
 * libcut.inc
 * CUT 2.1
 *
 * Copyright (c) 2001-2002 Samuel A. Falvo II, William D. Tanksley
 * See LICENSE.TXT for details.
 *
 * Based on WDT's 'TestAssert' package.
 *
 * $log$
 */

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include "cut.h"

#ifndef BOOL		/* Just in case -- helps in portability */
#define BOOL int
#endif

#ifndef FALSE
#define FALSE (0)
#endif

#ifndef TRUE
#define TRUE 1
#endif

typedef struct NameStackItem   NameStackItem;
typedef struct NameStackItem  *NameStack;

struct NameStackItem
{
  NameStackItem *      next;
  char *               name;
  CUTTakedownFunction *takedown;
};

static int            breakpoint = 0;
static int            count = 0;
static BOOL           test_hit_error = FALSE;
static NameStack      nameStack;

static void traceback( void );
static void cut_exit( void );

/* I/O Functions */

static void print_string( char *string )
{
  doLog(0, "%s", string );
  fflush( stdout );
}

static void print_string_as_error( char *filename, int lineNumber, char *string )
{
  doLog(0, "[31m%s(%d): %s[00m", filename, lineNumber, string );
  fflush( stdout );
}

static void print_integer_as_expected( int i )
{
  doLog(0, "(signed) %d (unsigned) %u (hex) 0x%08lX", i, i, i );
}

static void print_integer( int i )
{
  doLog(0, "%d", i );
  fflush( stdout );
}

static void print_integer_in_field( int i, int width )
{
  doLog(0, "%*d", width, i );
  fflush( stdout );
}

static void new_line( void )
{
  doLog(0, "\n" );
  fflush( stdout );
}

static void print_character( char ch )
{
  doLog(0, "%c", ch );
  fflush( stdout );
}

static void dot( void )
{
  print_character( '.' );
}

static void space( void )
{
  print_character( ' ' );
}

/* Name Stack Functions */

static NameStackItem *stack_topOf( NameStack *stack )
{
  return *stack;
}

static BOOL stack_isEmpty( NameStack *stack )
{
  return stack_topOf( stack ) == NULL;
}

static BOOL stack_isNotEmpty( NameStack *stack )
{
  return !( stack_isEmpty( stack ) );
}

static void stack_push( NameStack *stack, char *name, CUTTakedownFunction *tdfunc )
{
  NameStackItem *item;

  item = (NameStackItem *)( malloc( sizeof( NameStackItem ) ) );
  if( item != NULL )
  {
    item -> next = stack_topOf( stack );
    item -> name = name;
    item -> takedown = tdfunc;

    *stack = item;
  }
}

static void stack_drop( NameStack *stack )
{
  NameStackItem *oldItem;

  if( stack_isNotEmpty( stack ) )
  {
    oldItem = stack_topOf( stack );
    *stack = oldItem -> next;

    free( oldItem );
  }
}

/* CUT Initialization and Takedown  Functions */

void cut_init( int brkpoint )
{
  breakpoint = brkpoint;
  count = 0;
  test_hit_error = FALSE;
  nameStack = NULL;

  if( brkpoint >= 0 )
  {
    print_string( "Breakpoint at test " );
    print_integer( brkpoint );
    new_line();
  }
}

void cut_exit( void )
{
  exit( test_hit_error != FALSE );
}

/* User Interface functions */

static void print_group( int position, int base, int leftover )
{
  if( !leftover )
    return;

  print_integer_in_field( base, position );
  while( --leftover )
    dot();
}

static void print_recap( int count )
{
  int countsOnLastLine = count % 50;
  int groupsOnLastLine = countsOnLastLine / 10;
  int dotsLeftOver = countsOnLastLine % 10;
  int lastGroupLocation =
     countsOnLastLine - dotsLeftOver + ( 4 * groupsOnLastLine ) + 5;

  if( dotsLeftOver == 0 )
  {
    if( countsOnLastLine == 0 )
      lastGroupLocation = 61;
    else
      lastGroupLocation -= 14;

    print_group( lastGroupLocation, countsOnLastLine-10, 10);
  }
  else
  {
    print_group(
                lastGroupLocation,
                countsOnLastLine - dotsLeftOver,
                dotsLeftOver
               );
  }
}

void cut_break_formatting( void ) // DEPRECATED: Do not use in future software
{
  new_line();
}

void cut_resume_formatting( void )
{
  new_line();
  print_recap( count );
}

void cut_interject( const char *comment, ... )
{
  va_list marker;
  va_start(marker,comment);
  
  cut_break_formatting();
  vprintf(comment,marker);
  cut_resume_formatting();
  
  va_end(marker);
}

/* Test Progress Accounting functions */

void __cut_mark_point( char *filename, int lineNumber )
{
  /*if( ( count % 10 ) == 0 )
  {
    if( ( count % 50 ) == 0 )
      new_line();

    print_integer_in_field( count, 5 );
  }
  else
    dot();*/

  count++;
  if( count == breakpoint )
  {
    print_string_as_error( filename, lineNumber, "Breakpoint hit" );
    new_line();
    traceback();
    cut_exit();
  }
}

void __cut_assert_equals( // DEPRECATED: Do not use in future software
                         char *filename,
                         int   lineNumber,
                         char *message,
                         char *expression,
                         BOOL  success,
                         int   expected
                        )
{
  __cut_mark_point( filename, lineNumber );
  
  if( success != FALSE )
    return;
  
  cut_break_formatting();
  print_string_as_error( filename, lineNumber, message );
  new_line();
  print_string_as_error( filename, lineNumber, "Failed expression: " );
  print_string( expression );
  new_line();
  print_string_as_error( filename, lineNumber, "Actual value: " );
  print_integer_as_expected( expected );
  new_line();

  test_hit_error = TRUE;
  cut_resume_formatting();
}


void __cut_assert(
                  char *filename,
                  int   lineNumber,
                  char *message,
                  char *expression,
                  BOOL  success
                 )
{
  __cut_mark_point( filename, lineNumber );
  
  if( success != FALSE )
    return;
  
  cut_break_formatting();
  print_string_as_error( filename, lineNumber, message );
  new_line();
  print_string_as_error( filename, lineNumber, "Failed expression: " );
  print_string( expression );
  new_line();

  test_hit_error = TRUE;
  cut_resume_formatting();
}


/* Test Delineation and Teardown Support Functions */

static void traceback()
{
  if( stack_isNotEmpty( &nameStack ) )
    print_string( "Traceback" );
  else
    print_string( "(No traceback available.)" );

  while( stack_isNotEmpty( &nameStack ) )
  {
    print_string( ": " );
    print_string( stack_topOf( &nameStack ) -> name );

    if( stack_topOf( &nameStack ) -> takedown != NULL )
    {
      print_string( "(taking down)" );
      stack_topOf( &nameStack ) -> takedown();
    }

    stack_drop( &nameStack );

    if( stack_isNotEmpty( &nameStack ) )
      space();
  }

  new_line();
}

void cut_start( char *name, CUTTakedownFunction *takedownFunction )
{
  stack_push( &nameStack, name, takedownFunction );
}

int __cut_check_errors( char *filename, int lineNumber )
{
  if( test_hit_error || stack_isEmpty( &nameStack ) )
  {
    cut_break_formatting();
    if( stack_isEmpty( &nameStack ) )
      print_string_as_error( filename, lineNumber, "Missing cut_start(); no traceback possible." );
    else
      traceback();

    cut_exit();
  } else return 1;
}

void __cut_end( char *filename, int lineNumber, char *closingFrame )
{
  if( test_hit_error || stack_isEmpty( &nameStack ) )
  {
    cut_break_formatting();
    if( stack_isEmpty( &nameStack ) )
      print_string_as_error( filename, lineNumber, "Missing cut_start(); no traceback possible." );
    else
      traceback();

    cut_exit();
  }
  else
  {
    if( strcmp( stack_topOf( &nameStack ) -> name, closingFrame ) == 0 )
      stack_drop( &nameStack );
    else
    {
      print_string_as_error( filename, lineNumber, "Mismatched cut_end()." );
      traceback();
      cut_exit();
    }
  }
}



extern void __CUT_BRINGUP__Door( void );
extern void __CUT__Test_Door_Config( void );
extern void __CUT__Test_Door_TimeLock( void );
extern void __CUT_TAKEDOWN__Door( void );
extern void __CUT_BRINGUP__Deposit( void );
extern void __CUT__Test_Deposit_Auto( void );
extern void __CUT__Test_Deposit_Manual( void );
extern void __CUT__Test_Deposit_Max_Qty( void );
extern void __CUT_TAKEDOWN__Deposit( void );
extern void __CUT_BRINGUP__Extraction( void );
extern void __CUT__Test_Extraction_Test1( void );
extern void __CUT_TAKEDOWN__Extraction( void );
extern void __CUT_BRINGUP__ExtractionWorkflow( void );
extern void __CUT__Test_ExtractionWorkflow( void );
extern void __CUT__Test_ExtractionWorkflowWithoutTimeDelay( void );
extern void __CUT_TAKEDOWN__ExtractionWorkflow( void );
extern void __CUT_BRINGUP__InstaDrop( void );
extern void __CUT__Test_InstaDrop( void );
extern void __CUT_TAKEDOWN__InstaDrop( void );


int main( int argc, char *argv[] )
{
  if ( argc == 1 )
    cut_init( -1 );
  else cut_init( atoi( argv[1] ) );


  cut_start( "group-Door", __CUT_TAKEDOWN__Door );
  __CUT_BRINGUP__Door();
  cut_check_errors();
    cut_start( "Test_Door_Config", 0 );
    __CUT__Test_Door_Config();
    cut_end( "Test_Door_Config" );
    cut_start( "Test_Door_TimeLock", 0 );
    __CUT__Test_Door_TimeLock();
    cut_end( "Test_Door_TimeLock" );
  cut_end( "group-Door" );
  __CUT_TAKEDOWN__Door();


  cut_start( "group-Deposit", __CUT_TAKEDOWN__Deposit );
  __CUT_BRINGUP__Deposit();
  cut_check_errors();
    cut_start( "Test_Deposit_Auto", 0 );
    __CUT__Test_Deposit_Auto();
    cut_end( "Test_Deposit_Auto" );
    cut_start( "Test_Deposit_Manual", 0 );
    __CUT__Test_Deposit_Manual();
    cut_end( "Test_Deposit_Manual" );
    cut_start( "Test_Deposit_Max_Qty", 0 );
    __CUT__Test_Deposit_Max_Qty();
    cut_end( "Test_Deposit_Max_Qty" );
  cut_end( "group-Deposit" );
  __CUT_TAKEDOWN__Deposit();


  cut_start( "group-Extraction", __CUT_TAKEDOWN__Extraction );
  __CUT_BRINGUP__Extraction();
  cut_check_errors();
    cut_start( "Test_Extraction_Test1", 0 );
    __CUT__Test_Extraction_Test1();
    cut_end( "Test_Extraction_Test1" );
  cut_end( "group-Extraction" );
  __CUT_TAKEDOWN__Extraction();


  cut_start( "group-ExtractionWorkflow", __CUT_TAKEDOWN__ExtractionWorkflow );
  __CUT_BRINGUP__ExtractionWorkflow();
  cut_check_errors();
    cut_start( "Test_ExtractionWorkflow", 0 );
    __CUT__Test_ExtractionWorkflow();
    cut_end( "Test_ExtractionWorkflow" );
    cut_start( "Test_ExtractionWorkflowWithoutTimeDelay", 0 );
    __CUT__Test_ExtractionWorkflowWithoutTimeDelay();
    cut_end( "Test_ExtractionWorkflowWithoutTimeDelay" );
  cut_end( "group-ExtractionWorkflow" );
  __CUT_TAKEDOWN__ExtractionWorkflow();


  cut_start( "group-InstaDrop", __CUT_TAKEDOWN__InstaDrop );
  __CUT_BRINGUP__InstaDrop();
  cut_check_errors();
    cut_start( "Test_InstaDrop", 0 );
    __CUT__Test_InstaDrop();
    cut_end( "Test_InstaDrop" );
  cut_end( "group-InstaDrop" );
  __CUT_TAKEDOWN__InstaDrop();


  cut_break_formatting();
  doLog(0,"Done.");
  return 0;
}

