HEADERS = list.h hashtable.h
OBJECTS = list.o hashtable.o

default: lexer


%.o: %.c %(HEADERS)
	gcc -c $< -o $@

lexer: $(OBJECTS)
	lex main.l
	gcc $(OBJECTS) lex.yy.c -o $@ -lfl

clean:
	-rm -f $(OBJECTS)
	-rm -f lexer
	-rm -f lex.yy.c