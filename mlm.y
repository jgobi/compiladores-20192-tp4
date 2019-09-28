%{
#include <stdio.h>

void yyerror(char *c);
int yylex(void);
%}

%token PROGRAM BEGIN END IF THEN ELSE DO WHILE UNTIL READ WRITE ASSIGN TYPE BOOLEAN_CONST INTEGER_CONST REAL_CONST CHAR_CONST RELOP ADDOP MULOP IDENTIFIER

%right THEN ELSE

%%

program:
    PROGRAM IDENTIFIER ';' decl_list compound_stmt
    ;

decl_list:
    decl_list ';' decl
    | decl
    ;

decl:
    ident_list ':' TYPE
    ;

ident_list:
    ident_list ',' IDENTIFIER
    | IDENTIFIER
    ;

compound_stmt:
    BEGIN stmt_list END
    ;

stmt_list:
    stmt_list ';' stmt
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
    IDENTIFIER ASSIGN expr
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
    READ '(' ident_list ')'
    ;

write_stmt:
    WRITE '(' expr_list ')'
    ;

expr_list:
    expr
    | expr_list ',' expr
    ;

expr:
    simple_expr
    | simple_expr RELOP simple_expr
    ;

simple_expr:
    term
    | simple_expr ADDOP term
    ;

term:
    factor_a
    | term MULOP factor_a
    ;

factor_a:
    '-' factor
    | factor
    ;

factor:
    IDENTIFIER
    | constant
    | '(' expr ')'
    | "NOT" factor
    ;

constant:
    INTEGER_CONST
    | REAL_CONST
    | CHAR_CONST
    | BOOLEAN_CONST
    ;


%%

void yyerror(char *c) {
    printf("Erro: %s\n", c);
}

int main() {
    yyparse();
    return 0;
}