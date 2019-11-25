#ifndef VAL__H
#define VAL__H

#include "symbol_table.h"

typedef struct val_t {
    st_node_t *st_node;
    char *string;
} val_t;


#endif  // VAL__H