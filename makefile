HEADERS = hashtable.h list.h
OBJECTS = hashtable.o list.o

default: lexer

%.o: %.c %(HEADERS)
	gcc -c $< -o $@

lexer: $(OBJECTS)
	gcc $(OBJECTS) -o $@

clean:
	-rm -f $(OBJECTS)
	-rm -f lexer