OBJECTS = $(patsubst %.cpp, %.o, $(wildcard *.cpp))
HEADERS = $(wildcard *.h)

CXX = g++
CXXFLAGS = -g -std=c++17 -O3

default: parser clean

PREREQUIRE = parser.o lexer.o

%.o: %.cpp %(HEADERS)
	$(CXX) $(CXXFLAGS) -c $< -o $@

%.cpp: %.yy
	bison --output=$*.cpp --defines=$*.h -v $*.yy

%.cpp: %.lex
	flex  --outfile=$*.cpp --header-file=$*.h $*.lex

parser: $(OBJECTS) $(PREREQUIRE)
	$(CXX) $(CXXFLAGS) $(PREREQUIRE) $(OBJECTS) -o $@ -lfl

clean:
	-rm -f $(OBJECTS)
	-rm -f $(PREREQUIRE)
	-rm -f parser.h
	-rm -f lexer.h