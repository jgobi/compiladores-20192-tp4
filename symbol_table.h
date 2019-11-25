#ifndef SYMBOL_TABLE__H
#define SYMBOL_TABLE__H

typedef enum st_type_t { BOOLEAN_T, CHAR_T, INTEGER_T, REAL_T } st_type_t;
char st_types[4][8] = { "boolean", "char", "integer", "real" };

typedef struct st_node_t {
    char name[64];
    st_type_t type;
    int block;
    int line;
} st_node_t;

typedef struct symbol_table_t {
    unsigned len;
    unsigned max;
    unsigned cur_block;
    st_node_t** nodes;
} symbol_table_t;

symbol_table_t* st_alloc (unsigned max_size);
void st_free (symbol_table_t *st);
st_node_t* st_lookup (symbol_table_t *st, char *symbol);
int st_insert (symbol_table_t *st, st_node_t *node);

st_node_t* st_create_node (char *symbol, st_type_t type, unsigned line);

unsigned st_enter_block (symbol_table_t *st);
unsigned st_leave_block (symbol_table_t *st);

#endif  // SYMBOL_TABLE__H
