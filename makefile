HEADERS = list.h hashtable.h
OBJECTS = list.o hashtable.o

default: lexer


%.o: %.cpp %(HEADERS)
	gcc -c $< -o $@

lexer: $(OBJECTS)
	bison -d -v main.y
	flex main.l
	gcc -g $(OBJECTS) lex.yy.c main.tab.c  -o $@ -lfl

clean:
	-rm -f $(OBJECTS)
	-rm -f lexer
	-rm -f lex.yy.c
	-rm -f main.tab.c
	-rm -f main.tab.h