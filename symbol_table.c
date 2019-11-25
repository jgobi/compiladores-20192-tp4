#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbol_table.h"

symbol_table_t* st_alloc (unsigned max_size) {
    symbol_table_t* st = (symbol_table_t*) malloc(sizeof (symbol_table_t));
    st->max = max_size;
    st->len = 0;
    st->cur_block = 0;
    st->nodes = (st_node_t**) malloc(max_size * sizeof (st_node_t*));
    return st;
};
void st_free (symbol_table_t *st) {
    free(st->nodes);
    free(st);
};
st_node_t* st_lookup (symbol_table_t *st, char *symbol) {
    for (unsigned i = 0; i<(st->len); i++) {
        if (strcmp(st->nodes[i]->name, symbol) == 0) {
            return st->nodes[i];
        }
    }
    return NULL;
};

int st_insert (symbol_table_t *st, st_node_t *node) {
    if (st->len < st->max) {
        node->block = st->cur_block;
        *(st->nodes + st->len) = node;
        st->len++;
        return 1;
    } else {
        return 0;
    }
};

st_node_t* st_create_node (char *symbol, st_type_t type, unsigned line) {
    st_node_t* node = malloc(sizeof (st_node_t));
    node->block = 0;
    node->line = line;
    node->name[0] = '\0';
    node->type = type;
    strcpy(node->name, symbol);
    return node;
};

void st_print (symbol_table_t *st) {
    printf("idx\tblock\tline\ttype\t\tidentifier\n");
    for (unsigned i = 0; i<(st->len); i++) {
        st_node_t* node = (st->nodes + i);
        printf("%u\t%u\t%u\t%s\t\t%s\n", i, node->block, node->line, st_types[node->type], node->name);
    }
    printf("\nlength: %u\tmax size: %u\tfree: %u\n", st->len, st->max, st->max-st->len);
};

unsigned st_enter_block (symbol_table_t *st) {
    return ++(st->cur_block);
};

unsigned st_leave_block (symbol_table_t *st) {
    return --(st->cur_block);
};