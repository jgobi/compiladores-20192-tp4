%{
#include <stdio.h>
#include <stdlib.h>

void yyerror(char const *c);
int yylex(void);

extern int num_linha;
symbol_table_t* st = st_alloc(1024);

char variaveis[100][10];
int count = 0;

unsigned temp_count = 0;

%}

%token PROGRAM BEGIN_T END IF THEN ELSE DO WHILE UNTIL READ WRITE TYPE BOOLEAN_CONST INTEGER_CONST REAL_CONST CHAR_CONST RELOP ADDOP MULOP IDENTIFIER
%token TWO_DOTS DOT_COMMA COMMA OPEN_PAR CLOSE_PAR ASSIGN NOT MINUS

%code requires {
    #include "symbol_table.h"
}

%union {
  int intval;
  double val;
  char cha;
  char *string;
  st_node_t *node;
}

%right THEN ELSE // https://stackoverflow.com/a/12734499

%define parse.error verbose

%type <intval> INTEGER_CONST BOOLEAN_CONST
%type <val> REAL_CONST
%type <cha> CHAR_CONST
%type <string> IDENTIFIER TYPE RELOP ADDOP MULOP

%type <node> constant ident_list expr assign_stmt expr_list simple_expr term factor_a factor

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
        for(int i = 0; i < count; i++) {
            st_node_t* node = st_lookup(st, $1);
            if(node != NULL) printf("Erro: variavel %s ja definida.\n", $1);
            else {
                st_insert(st, variaveis[i], $3);
            } 
        }
        count = 0;    
    }
    ;

ident_list:
    ident_list COMMA IDENTIFIER    {
        $$ = $3;
        strcpy(variaveis[count], $$);
        count++;
    }
    | IDENTIFIER    {
        $$ = $1;
        strcpy(variaveis[count], $$);
        count++;
    }
    ;

compound_stmt:
    BEGIN_T stmt_list END    
    ;

stmt_list:
    stmt_list DOT_COMMA stmt    
    | stmt    
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
            printf("Erro: variavel %s nao definida.\n", $1);
        } else {

        }
     }
    ;

if_stmt:
    IF cond THEN stmt    
    | IF cond THEN stmt ELSE stmt    
    ;

cond:
    expr    
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
    READ OPEN_PAR ident_list CLOSE_PAR    
    ;

write_stmt:
    WRITE OPEN_PAR expr_list CLOSE_PAR    
    ;

expr_list:
    expr    
    | expr_list COMMA expr    
    ;

expr:
    simple_expr    
    | simple_expr NOT simple_expr    
    | simple_expr RELOP simple_expr    
    ;

simple_expr:
    term    
    | simple_expr MINUS term    
    | simple_expr ADDOP term    
    ;

term:
    factor_a    
    | term MULOP factor_a    
    ;

factor_a:
    MINUS factor    
    | factor    
    ;

factor:
    IDENTIFIER    { 
        st_node_t* node = st_lookup(st, $1);
        if(node == NULL) {
            printf("Erro: variavel %s nao definida.\n", $1);
        } else {

        }
    }
    | constant    
    | OPEN_PAR expr CLOSE_PAR    
    | NOT factor    
    ;

constant:
    INTEGER_CONST {
        char tname[16];
        snprintf(tname, 15, "_t%u", temp_count++);
        $$ = st_create_node(tname, INTEGER_T, num_linha);
    }
    | REAL_CONST {
        char tname[16];
        snprintf(tname, 15, "_t%u", temp_count++);
        $$ = st_create_node(tname, REAL_T, num_linha);
    }
    | CHAR_CONST {
        char tname[16];
        snprintf(tname, 15, "_t%u", temp_count++);
        $$ = st_create_node(tname, CHAR_T, num_linha);
    }
    | BOOLEAN_CONST {
        char tname[16];
        snprintf(tname, 15, "_t%u", temp_count++);
        $$ = st_create_node(tname, BOOLEAN_T, num_linha);
    }
    ;


%%
int error = 0;
void yyerror(char const *s) {
    fprintf(stderr,"Erro na linha %i: %s\n", num_linha-1, s);
    error = 1;
}

int main() {
    yyparse();
    if (!error) fprintf(stderr, "=== %i linhas analisadas ===\n", num_linha-1);
    return 0;
}