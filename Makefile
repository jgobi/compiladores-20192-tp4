run: comp
	./a.out < teste.mlm
lex: 
	flex mlm.l
sin: lex
	bison -d mlm.y
comp: sin
	gcc lex.yy.c mlm.tab.c symbol_table.c
