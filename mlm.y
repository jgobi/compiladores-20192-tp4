%{
#include <stdio.h>
#include <stdlib.h>

void yyerror(char const *c);
int yylex(void);

extern int num_linha;
%}

%token PROGRAM BEGIN_T END IF THEN ELSE DO WHILE UNTIL READ WRITE TYPE BOOLEAN_CONST INTEGER_CONST REAL_CONST CHAR_CONST RELOP ADDOP MULOP IDENTIFIER
%token TWO_DOTS DOT_COMMA COMMA OPEN_PAR CLOSE_PAR ASSIGN NOT MINUS

%union {
  int intval;
  double val;
  char cha;
  char *string;
}

%right THEN ELSE // https://stackoverflow.com/a/12734499

%define parse.error verbose

%type <intval> INTEGER_CONST

%%

program:
    PROGRAM IDENTIFIER DOT_COMMA decl_list compound_stmt    { printf("program: PROGRAM IDENTIFIER DOT_COMMA decl_list compound_stmt\n"); }
    ;

decl_list:
    decl_list DOT_COMMA decl    { printf("decl_list: decl_list DOT_COMMA decl\n"); }
    | decl    { printf("decl_list: decl\n"); }
    ;

decl:
    ident_list TWO_DOTS TYPE   { printf("decl: ident_list TWO_DOTS TYPE\n"); }
    ;

ident_list:
    ident_list COMMA IDENTIFIER    { printf("ident_list: ident_list COMMA IDENTIFIER\n"); }
    | IDENTIFIER    { printf("ident_list: IDENTIFIER\n"); }
    ;

compound_stmt:
    BEGIN_T stmt_list END    { printf("compound_stmt: BEGIN_T stmt_list END\n"); }
    ;

stmt_list:
    stmt_list DOT_COMMA stmt    { printf("stmt_list: stmt_list DOT_COMMA stmt\n"); }
    | stmt    { printf("stmt_list: stmt\n"); }
    ;

stmt:
    assign_stmt    { printf("stmt: assign_stmt\n"); }
    | if_stmt    { printf("stmt: if_stmt\n"); }
    | loop_stmt    { printf("stmt: loop_stmt\n"); }
    | read_stmt    { printf("stmt: read_stmt\n"); }
    | write_stmt    { printf("stmt: write_stmt\n"); }
    | compound_stmt    { printf("stmt: compound_stmt\n"); }
    ;

assign_stmt:
    IDENTIFIER ASSIGN expr    { printf("assign_stmt: IDENTIFIER ASSIGN expr\n"); }
    ;

if_stmt:
    IF cond THEN stmt    { printf("if_stmt: IF cond THEN stmt\n"); }
    | IF cond THEN stmt ELSE stmt    { printf("if_stmt: IF cond THEN stmt ELSE stmt\n"); }
    ;

cond:
    expr    { printf("cond: expr\n"); }
    ;

loop_stmt:
    stmt_prefix DO stmt_list stmt_suffix    { printf("loop_stmt: stmt_prefix DO stmt_list stmt_suffix\n"); }
    ;

stmt_prefix:
    WHILE cond    { printf("stmt_prefix: WHILE cond\n"); }
    | { printf("stmt_prefix: \n"); }
    ;

stmt_suffix:
    UNTIL cond    { printf("stmt_suffix: UNTIL cond\n"); }
    | END    { printf("stmt_suffix: END\n"); }
    ;

read_stmt:
    READ OPEN_PAR ident_list CLOSE_PAR    { printf("read_stmt: READ OPEN_PAR ident_list CLOSE_PAR\n"); }
    ;

write_stmt:
    WRITE OPEN_PAR expr_list CLOSE_PAR    { printf("write_stmt: WRITE OPEN_PAR expr_list CLOSE_PAR\n"); }
    ;

expr_list:
    expr    { printf("expr_list: expr\n"); }
    | expr_list COMMA expr    { printf("expr_list: expr_list COMMA expr\n"); }
    ;

expr:
    simple_expr    { printf("expr: simple_expr\n"); }
    | simple_expr NOT simple_expr    { printf("expr: simple_expr NOT simple_expr\n"); }
    | simple_expr RELOP simple_expr    { printf("expr: simple_expr RELOP simple_expr\n"); }
    ;

simple_expr:
    term    { printf("simple_expr: term\n"); }
    | simple_expr MINUS term    { printf("simple_expr: simple_expr MINUS term\n"); }
    | simple_expr ADDOP term    { printf("simple_expr: simple_expr ADDOP term\n"); }
    ;

term:
    factor_a    { printf("term: factor_a\n"); }
    | term MULOP factor_a    { printf("term: term MULOP factor_a\n"); }
    ;

factor_a:
    MINUS factor    { printf("factor_a: MINUS factor\n"); }
    | factor    { printf("factor_a: factor\n"); }
    ;

factor:
    IDENTIFIER    { printf("factor: IDENTIFIER\n"); }
    | constant    { printf("factor: constant\n"); }
    | OPEN_PAR expr CLOSE_PAR    { printf("factor: OPEN_PAR expr CLOSE_PAR\n"); }
    | NOT factor    { printf("factor: NOT factor\n"); }
    ;

constant:
    INTEGER_CONST    { printf("constant: INTEGER_CONST %i\n", $1); }
    | REAL_CONST    { printf("constant: REAL_CONST\n"); }
    | CHAR_CONST    { printf("constant: CHAR_CONST\n"); }
    | BOOLEAN_CONST    { printf("constant: BOOLEAN_CONST\n"); }
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