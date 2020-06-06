HEADERS = list.h hashtable.h symbol_table.h
OBJECTS = list.o hashtable.o symbol_table.o

CC = g++
CFLAGS = -g -std=c++17 -O3

default: parser


%.o: %.cpp %(HEADERS)
	$(CC) $(CFLAGS) -c $< -o $@

parser: $(OBJECTS)
	bison -d -v parser.y
	flex lexer.l
	$(CC) $(CFLAGS) $(OBJECTS) -Wall lex.yy.c parser.tab.c -o $@ -lfl

clean:
	-rm -f $(OBJECTS)
	-rm -f parser
	-rm -f lex.yy.c
	-rm -f parser.tab.c
	-rm -f parser.tab.h