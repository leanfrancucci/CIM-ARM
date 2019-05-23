#include <stdio.h>
#include <stdlib.h>
#include "state_machine.h"

/**/
BOOL GUARD_CONDITION_FALSE(StateMachine *sm)
{
  return FALSE;
}

/**/
BOOL GUARD_CONDITION_TRUE(StateMachine *sm)
{
  return TRUE;
}

/**/
void executeStateMachine(StateMachine *sm, int event)
{
  State *newState = NULL;
  State *currentState;
  Transition *t;

  sm->currentEvent = event;

  currentState = sm->currentState;
  t = &currentState->transitions[0];

  for (t = &currentState->transitions[0]; ; t++) {

    if ((t->event == event || t->event == SM_ANY) &&
        (t->guardCondition == NULL || t->guardCondition(sm))) {
      newState = t->nextState;
      break;
    }

  }

  sm->lastState = sm->currentState;
  sm->currentState = newState;

  if (currentState && newState != currentState && currentState->exit)
    currentState->exit(sm);
  
  if (t->action) t->action(sm);

  if (newState && newState != currentState && newState->entry)
    newState->entry(sm);

}

/**/
void startStateMachine(StateMachine *sm)
{
  State *currentState;
  currentState = sm->currentState;
  if (currentState && currentState->entry) currentState->entry(sm);
}

/**/
StateMachine * newStateMachine(State *initialState, void *context)
{
  StateMachine *sm;

  sm = malloc(sizeof(StateMachine));

  sm->currentState = initialState;
  sm->context = context;
  sm->lastState = NULL;

  return sm;
}

/**/
void gotoState(StateMachine *sm, State *newState)
{
  sm->lastState = sm->currentState;
  sm->currentState = newState;
  if (newState && newState->entry)
    newState->entry(sm);
}
