#ifndef STATE_MACHINE_H
#define STATE_MACHINE_H

#include <stdio.h>
#include <stdlib.h>
#include "system/lang/all.h"

#define SM_ANY      -1

#define smGetCurrentState(a) ((a)->currentState)
#define smGetCurrentContext(a) ((a)->context)
#define smGetCurrentEvent(a) ((a)->currentEvent)
#define smGetLastState(a) ((a)->lastState)

typedef struct State State;
typedef struct Transition Transition;
typedef struct StateMachine StateMachine;

/**/
typedef void(StateAction)(StateMachine *sm);
typedef BOOL(GuardCondition)(StateMachine *sm);

/**/
struct Transition {
  int event;
  GuardCondition *guardCondition;
  StateAction *action;
  State *nextState;
};

/**/
struct State {
  StateAction *entry;
  StateAction *exit;
  Transition *transitions;
};

/**/
struct StateMachine {
  State *currentState;
  State *lastState;
  void  *context;
  int    currentEvent;
};

extern BOOL GUARD_CONDITION_FALSE(StateMachine *sm);
extern BOOL GUARD_CONDITION_TRUE(StateMachine *sm);

void gotoState(StateMachine *sm, State *newState);
void executeStateMachine(StateMachine *sm, int event);
StateMachine * newStateMachine(State *initialState, void *context);
void startStateMachine(StateMachine *sm);

#endif
