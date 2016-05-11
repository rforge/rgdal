/* Copyright (c) 2016 Barry Rowlingson */

#include <projects.h>

extern "C" {
int inversetest(PJ *P){
  return (P->inv ? 1: 0);

}

}
