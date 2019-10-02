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
    PROGRAM IDENTIFIER DOT_COMMA decl_list compound_stmt    { printf("PROGRAM IDENTIFIER DOT_COMMA decl_list compound_stmt\n"); }
    ;

decl_list:
    decl_list DOT_COMMA decl    { printf("decl_list DOT_COMMA decl\n"); }
    | decl    { printf("decl\n"); }
    ;

decl:
    ident_list TWO_DOTS TYPE   { printf("ident_list TWO_DOTS TYPE\n"); }
    ;

ident_list:
    ident_list COMMA IDENTIFIER    { printf("ident_list COMMA IDENTIFIER\n"); }
    | IDENTIFIER    { printf("IDENTIFIER\n"); }
    ;

compound_stmt:
    BEGIN_T stmt_list END    { printf("BEGIN_T stmt_list END\n"); }
    ;

stmt_list:
    stmt_list DOT_COMMA stmt    { printf("stmt_list DOT_COMMA stmt\n"); }
    | stmt    { printf("stmt\n"); }
    ;

stmt:
    assign_stmt    { printf("assign_stmt\n"); }
    | if_stmt    { printf("if_stmt\n"); }
    | loop_stmt    { printf("loop_stmt\n"); }
    | read_stmt    { printf("read_stmt\n"); }
    | write_stmt    { printf("write_stmt\n"); }
    | compound_stmt    { printf("compound_stmt\n"); }
    ;

assign_stmt:
    IDENTIFIER ASSIGN expr    { printf("IDENTIFIER ASSIGN expr\n"); }
    ;

if_stmt:
    IF cond THEN stmt    { printf("IF cond THEN stmt\n"); }
    | IF cond THEN stmt ELSE stmt    { printf("IF cond THEN stmt ELSE stmt\n"); }
    ;

cond:
    expr    { printf("expr\n"); }
    ;

loop_stmt:
    stmt_prefix DO stmt_list stmt_suffix    { printf("stmt_prefix DO stmt_list stmt_suffix\n"); }
    ;

stmt_prefix:
    WHILE cond    { printf("WHILE cond\n"); }
    |
    ;

stmt_suffix:
    UNTIL cond    { printf("UNTIL cond\n"); }
    | END    { printf("END\n"); }
    ;

read_stmt:
    READ OPEN_PAR ident_list CLOSE_PAR    { printf("READ OPEN_PAR ident_list CLOSE_PAR\n"); }
    ;

write_stmt:
    WRITE OPEN_PAR expr_list CLOSE_PAR    { printf("WRITE OPEN_PAR expr_list CLOSE_PAR\n"); }
    ;

expr_list:
    expr    { printf("expr\n"); }
    | expr_list COMMA expr    { printf("expr_list COMMA expr\n"); }
    ;

expr:
    simple_expr    { printf("simple_expr\n"); }
    | simple_expr NOT simple_expr    { printf("simple_expr NOT simple_expr\n"); }
    | simple_expr RELOP simple_expr    { printf("simple_expr RELOP simple_expr\n"); }
    ;

simple_expr:
    term    { printf("term\n"); }
    | simple_expr MINUS term    { printf("simple_expr MINUS term\n"); }
    | simple_expr ADDOP term    { printf("simple_expr ADDOP term\n"); }
    ;

term:
    factor_a    { printf("factor_a\n"); }
    | term MULOP factor_a    { printf("term MULOP factor_a\n"); }
    ;

factor_a:
    MINUS factor    { printf("MINUS factor\n"); }
    | factor    { printf("factor\n"); }
    ;

factor:
    IDENTIFIER    { printf("IDENTIFIER\n"); }
    | constant    { printf("constant\n"); }
    | OPEN_PAR expr CLOSE_PAR    { printf("OPEN_PAR expr CLOSE_PAR\n"); }
    | NOT factor    { printf("NOT factor\n"); }
    ;

constant:
    INTEGER_CONST    { printf("INTEGER_CONST\n"); }
    | REAL_CONST    { printf("REAL_CONST\n"); }
    | CHAR_CONST    { printf("CHAR_CONST\n"); }
    | BOOLEAN_CONST    { printf("BOOLEAN_CONST\n"); }
    ;


%%

void yyerror(char const *s) {
    printf("Erro: %s\n", s);
}

int main() {
    yyparse();
    return 0;
}