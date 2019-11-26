%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbol_table.h"

#define GENERATED_CODE_MAX 8192
#define GENERATED_CODE_LINE_MAX 128
#define MAX_STACK_SIZE 64

void yyerror(char const *c);
int yylex(void);

const char st_types[4][8] = { "boolean", "char", "integer", "real" };

extern int num_linha;
symbol_table_t* st;

char list_ident[100][32];
int count_ident = 0;

st_node_t *list_exprs[100];
int count_exprs = 0;

unsigned temp_count = 0;

char **codigo;
unsigned codigo_count = 0;

void gen_code (char *str) {
    strcpy(codigo[codigo_count++], str);
}

void backpatch_code (unsigned idx, char *str) {
    strcpy(codigo[idx], str);
}

unsigned stack[MAX_STACK_SIZE];
unsigned stack_count = 0;

%}

%token PROGRAM BEGIN_T END IF THEN ELSE DO WHILE UNTIL READ WRITE TYPE BOOLEAN_CONST INTEGER_CONST REAL_CONST CHAR_CONST RELOP ADDOP MULOP IDENTIFIER
%token TWO_DOTS DOT_COMMA COMMA OPEN_PAR CLOSE_PAR ASSIGN NOT MINUS

%code requires {
    #include "st_node_t.h"
}

%union {
  int intval;
  double val;
  char *string;
  st_node_tp node;
}

%right THEN ELSE // https://stackoverflow.com/a/12734499

%define parse.error verbose

%type <intval> INTEGER_CONST BOOLEAN_CONST
%type <val> REAL_CONST
%type <string> IDENTIFIER TYPE RELOP ADDOP MULOP CHAR_CONST

%type <node> constant factor_a factor term simple_expr expr cond

%%

program:
    PROGRAM IDENTIFIER DOT_COMMA decl_list compound_stmt    
    ;

decl_list:
    decl_list DOT_COMMA decl    
    | decl    
    ;

decl:
    ident_list TWO_DOTS TYPE   {
        for (int i = 0; i < count_ident; i++) {
            st_node_t* node = st_lookup(st, list_ident[i]);
            if (node != NULL) {
                fprintf(stderr, "Erro: redeclaracao da variavel %s, ja definida na linha %u.\n", list_ident[i], node->line);
                YYERROR;
            } else {
                st_type_t type = st_str2type($3);
                node = st_create_node(list_ident[i], type, num_linha);
                st_insert(st, node);

                char buffer[128];
                if (type == CHAR_T) {
                    snprintf(buffer, 127, "declare %s %s '\\0'", list_ident[i], $3);
                } else {
                    snprintf(buffer, 127, "declare %s %s 0", list_ident[i], $3);
                }
                gen_code(buffer);
            } 
        }
        count_ident = 0;
    }
    ;

ident_list:
    ident_list COMMA IDENTIFIER    {
        strcpy(list_ident[count_ident], $3);
        count_ident++;
    }
    | IDENTIFIER    {
        strcpy(list_ident[count_ident], $1);
        count_ident++;
    }
    ;

compound_stmt:
    BEGIN_T stmt_list END    
    ;

stmt_list:
    stmt_list DOT_COMMA stmt    
    | stmt    
    ;

stmt_if_else:
    stmt   {
        stack[stack_count] = codigo_count;
        stack_count++;
        gen_code("##");
    }
    ;

stmt:
    assign_stmt    
    | if_stmt    
    | loop_stmt    
    | read_stmt    
    | write_stmt    
    | compound_stmt    
    ;

assign_stmt:
    IDENTIFIER ASSIGN expr    { 
        st_node_t* node = st_lookup(st, $1);
        if(node == NULL) {
            fprintf(stderr, "Erro: uso de variavel '%s' nao definida na linha %u.\n", $1, num_linha);
            YYERROR;
        } else {
            char buffer[128];
            snprintf(buffer, 127, "assign %s %s", node->name, $3->name);
            gen_code(buffer);
        }
     }
    ;

if_stmt:
    IF cond THEN stmt    {
        char buffer[128];
        stack_count--;
        snprintf(buffer, 127, "branch %s %u", $2->name, codigo_count); 
        backpatch_code(stack[stack_count], buffer);
    }
    | IF cond THEN stmt_if_else ELSE stmt   {
        char buffer[128];
        stack_count--;
        // o topo da pilha está com a saída do stmt_if_else
        snprintf(buffer, 127, "jump %u", codigo_count); 
        backpatch_code(stack[stack_count], buffer);
        snprintf(buffer, 127, "branch %s %u", $2->name, stack[stack_count] + 1); 
        // o topo da pilha está com a saída do cond
        stack_count--;
        backpatch_code(stack[stack_count], buffer);
    } 
    ;

cond:
    expr    {
        $$ = $1;
        if(stack_count >= MAX_STACK_SIZE) {
            fprintf(stderr, "Stack overflow na linha %u.\n", num_linha);
            YYERROR;
        } else {
            stack[stack_count] = codigo_count;
            stack_count++;
            gen_code("#");
        }
        
    }
    ;

loop_stmt:
    stmt_prefix DO stmt_list stmt_suffix    
    ;

stmt_prefix:
    WHILE cond    
    | 
    ;

stmt_suffix:
    UNTIL cond    
    | END    
    ;

read_stmt:
    READ OPEN_PAR ident_list CLOSE_PAR    {
        char buffer[128];
        for (int i = 0; i < count_ident; i++) {
            st_node_t* node = st_lookup(st, list_ident[i]);
            if (node == NULL) {
                fprintf(stderr, "Erro: uso de variavel '%s' nao definida na linha %u.\n", list_ident[i], num_linha);
                YYERROR;
            } else {
                char buffer[128];
                snprintf(buffer, 127, "read %s %s", st_types[node->type], node->name);
                gen_code(buffer);
            } 
        }
        count_ident = 0;
    }
    ;

write_stmt:
    WRITE OPEN_PAR expr_list CLOSE_PAR    {
        char buffer[128];
        for (int i = 0; i < count_exprs; i++) {
            snprintf(buffer, 127, "write %s %s", st_types[list_exprs[i]->type], list_exprs[i]->name);
            gen_code(buffer);
        }
        count_exprs = 0;
    }
    ;

expr_list:
    expr    {
        list_exprs[count_exprs] = $1;
        count_exprs++;
    }
    | expr_list COMMA expr    {
        list_exprs[count_exprs] = $3;
        count_exprs++;
    }
    ;

expr:
    simple_expr    {
        $$ = $1;
    }
    | simple_expr RELOP simple_expr    {
        char tname[16];
        snprintf(tname, 15, "_t%u", temp_count++);
        $$ = st_create_node(tname, BOOLEAN_T, num_linha);
        st_insert(st, $$);
        char buffer[128];
        snprintf(buffer, 127, "declare %s boolean 0", tname);
        gen_code(buffer);
        snprintf(buffer, 127, "%s %s %s %s", $2, tname, $1->name, $3->name);
        gen_code(buffer);
    }
    ;

simple_expr:
    term    {
        $$ = $1;
    }
    | simple_expr MINUS term    {
        if (
            ($1->type == $3->type) &&
            ($1->type == INTEGER_T || $1->type == REAL_T)
        ) {
            char tname[16];
            snprintf(tname, 15, "_t%u", temp_count++);
            $$ = st_create_node(tname, $1->type, num_linha);
            st_insert(st, $$);
            char buffer[128];
            snprintf(buffer, 127, "declare %s %s 0", tname, st_types[$1->type]);
            gen_code(buffer);
            snprintf(buffer, 127, "- %s %s %s", tname, $1->name, $3->name);
            gen_code(buffer);
        } else {
            fprintf(stderr, "Erro: tipos '%s' e '%s' incompativeis com o operador '-' na linha %u.\n", st_types[$1->type], st_types[$3->type], num_linha);
            YYERROR;
        }
    }
    | simple_expr ADDOP term    {
        st_type_t type = -1;
        int is_logical = strcmp($2, "or") == 0;
        int is_error = 0;
        if (
            is_logical &&
            ($1->type == INTEGER_T || $1->type == BOOLEAN_T) &&
            ($3->type == INTEGER_T || $3->type == BOOLEAN_T)
        ) {
            type = BOOLEAN_T;
        } else if (
            !is_logical &&
            ($1->type == $3->type) &&
            ($1->type == INTEGER_T || $1->type == REAL_T)
        ) {
            type = $1->type;
        } else {
            is_error = 1;
            fprintf(stderr, "Erro: tipos '%s' e '%s' incompativeis com o operador '%s' na linha %u.\n", st_types[$1->type], st_types[$3->type], $2, num_linha);
            YYERROR;
        }
        if (!is_error) {
            char tname[16];
            snprintf(tname, 15, "_t%u", temp_count++);
            $$ = st_create_node(tname, $1->type, num_linha);
            st_insert(st, $$);
            char buffer[128];
            snprintf(buffer, 127, "declare %s %s 0", tname, st_types[type]);
            gen_code(buffer);
            snprintf(buffer, 127, "%s %s %s %s", $2, tname, $1->name, $3->name);
            gen_code(buffer);
        }
    }
    ;

term:
    factor_a    {
        $$ = $1;
    }
    | term MULOP factor_a    {
        st_type_t type = -1;
        int is_logical = strcmp($2, "and") == 0;
        int is_error = 0;
        if (
            is_logical &&
            ($1->type == INTEGER_T || $1->type == BOOLEAN_T) &&
            ($3->type == INTEGER_T || $3->type == BOOLEAN_T)
        ) {
            type = BOOLEAN_T;
        } else if (
            !is_logical &&
            ($1->type == $3->type) &&
            ($1->type == INTEGER_T || $1->type == REAL_T)
        ) {
            type = $1->type;
        } else {
            is_error = 1;
            fprintf(stderr, "Erro: tipos '%s' e '%s' incompativeis com o operador '%s' na linha %u.\n", st_types[$1->type], st_types[$3->type], $2, num_linha);
            YYERROR;
        }
        if (!is_error) {
            char tname[16];
            snprintf(tname, 15, "_t%u", temp_count++);
            $$ = st_create_node(tname, $1->type, num_linha);
            st_insert(st, $$);
            char buffer[128];
            snprintf(buffer, 127, "declare %s %s 0", tname, st_types[type]);
            gen_code(buffer);
            snprintf(buffer, 127, "%s %s %s %s", $2, tname, $1->name, $3->name);
            gen_code(buffer);
        }
    }
    ;

factor_a:
    MINUS factor    {
        if ($2->type == REAL_T || $2->type == INTEGER_T) {
            char tname[16];
            snprintf(tname, 15, "_t%u", temp_count++);
            $$ = st_create_node(tname, $2->type, num_linha);
            st_insert(st, $$);
            char buffer[128];
            snprintf(buffer, 127, "declare %s %s 0", tname, st_types[$2->type]);
            gen_code(buffer);
            snprintf(buffer, 127, "- %s 0 %s", tname, $2->name);
            gen_code(buffer);
        } else {
            fprintf(stderr, "Erro: tipo '%s' incompativel com o operador '-' na linha %u.\n", st_types[$2->type], num_linha);
            YYERROR;
        }
    }
    | factor    {
        $$ = $1;
    }
    ;

factor:
    IDENTIFIER    { 
        $$ = st_lookup(st, $1);
        if ($$ == NULL) {
            fprintf(stderr, "Erro: uso de variavel '%s' nao definida na linha %u.\n", $1, num_linha);
            YYERROR;
        }
    }
    | constant    {
        $$ = $1;
    }
    | OPEN_PAR expr CLOSE_PAR    {
        $$ = $2;
    }
    | NOT factor    {
        if ($2->type == BOOLEAN_T || $2->type == INTEGER_T) {
            char tname[16];
            snprintf(tname, 15, "_t%u", temp_count++);
            $$ = st_create_node(tname, BOOLEAN_T, num_linha);
            st_insert(st, $$);
            char buffer[128];
            snprintf(buffer, 127, "declare %s boolean 0", tname);
            gen_code(buffer);
            snprintf(buffer, 127, "not %s %s", tname, $2->name);
            gen_code(buffer);
        } else {
            fprintf(stderr, "Erro: tipo '%s' incompativel com o operador 'NOT' na linha %u.\n", st_types[$2->type], num_linha);
            YYERROR;
        }
    }
    ;

constant:
    INTEGER_CONST {
        char tname[16];
        snprintf(tname, 15, "_t%u", temp_count++);
        $$ = st_create_node(tname, INTEGER_T, num_linha);
        st_insert(st, $$);
        char buffer[128];
        snprintf(buffer, 127, "declare %s integer %i", tname, $1);
        gen_code(buffer);
    }
    | REAL_CONST {
        char tname[16];
        snprintf(tname, 15, "_t%u", temp_count++);
        $$ = st_create_node(tname, REAL_T, num_linha);
        st_insert(st, $$);
        char buffer[128];
        snprintf(buffer, 127, "declare %s real %lf", tname, $1);
        gen_code(buffer);
    }
    | CHAR_CONST {
        char tname[16];
        snprintf(tname, 15, "_t%u", temp_count++);
        $$ = st_create_node(tname, CHAR_T, num_linha);
        st_insert(st, $$);
        char buffer[128];
        snprintf(buffer, 127, "declare %s char %s", tname, $1);
        gen_code(buffer);
    }
    | BOOLEAN_CONST {
        char tname[16];
        snprintf(tname, 15, "_t%u", temp_count++);
        $$ = st_create_node(tname, BOOLEAN_T, num_linha);
        st_insert(st, $$);
        char buffer[128];
        snprintf(buffer, 127, "declare %s boolean %i", tname, $1);
        gen_code(buffer);
    }
    ;


%%
int error = 0;
void yyerror(char const *s) {
    fprintf(stderr,"Erro na linha %u: %s\n", num_linha, s);
    error = 1;
}

int main() {
    st = st_alloc(GENERATED_CODE_MAX * 2);
    codigo = (char**) malloc(GENERATED_CODE_MAX * sizeof (char*));
    for (unsigned i = 0; i < GENERATED_CODE_MAX; i++) {
        codigo[i] = (char*) malloc(GENERATED_CODE_LINE_MAX * sizeof (char));
    }

    yyparse();

    for (unsigned i = 0; i < codigo_count; i++) {
        printf("[%3u] %s\n", i, codigo[i]);
    }
    printf("[%3u] halt\n", codigo_count);
    printf("\n");
    st_print(st);

    if (!error) fprintf(stderr, "=== %i linhas analisadas ===\n", num_linha-1);

    for (unsigned i = 0; i < GENERATED_CODE_MAX; i++) {
        free(codigo[i]);
    }
    free(codigo);
    st_free(st);
    return 0;
}
