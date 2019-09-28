%{
#include <stdio.h>

void yyerror(char const *c);
int yylex(void);
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

%%

program:
    PROGRAM IDENTIFIER DOT_COMMA decl_list compound_stmt
    ;

decl_list:
    decl_list DOT_COMMA decl
    | decl
    ;

decl:
    ident_list TWO_DOTS TYPE
    ;

ident_list:
    ident_list COMMA IDENTIFIER
    | IDENTIFIER
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
    IDENTIFIER
    | constant
    | OPEN_PAR expr CLOSE_PAR
    | NOT factor
    ;

constant:
    INTEGER_CONST
    | REAL_CONST
    | CHAR_CONST
    | BOOLEAN_CONST
    ;


%%

void yyerror(char const *s) {
    printf("Erro: %s\n", s);
}

int main() {
    yyparse();
    return 0;
}