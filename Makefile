# I am a Makefile.
.PHONY: clean all

# Global
PROJ ?= DragonLisp

# Lexical Analysis
LEX = flex
LEXFLAGS ?= -T --hex

# Syntax Analysis
YACC = bison
YACCFLAGS ?= -Wall --color -v -t -d -Wcounterexamples
LANG = c++

# Compile C/C++ Code
CC = clang
CXX = clang++
OUTPUT ?= $(PROJ).exe

COMMONFLAGS ?= -g -Wall
CFLAGS ?= $(COMMONFLAGS) -std=c18
CXXFLAGS ?= $(COMMONFLAGS) -std=c++20

MISCOBJ = main DragonLispDriver AST
OBJS  = $(addsuffix .o, $(MISCOBJ))

all: compile

lexer:
	$(LEX) $(LEXFLAGS) $(PROJ).l

lexer_compile: lexer parser
	$(CXX) $(CXXFLAGS) -c -o lexer.o lex.yy.cc

parser:
	$(YACC) $(YACCFLAGS) --language=$(LANG) $(PROJ).y

parser_compile: parser
	$(CXX) $(CXXFLAGS) -c -o parser.o $(PROJ).tab.cc

misc_compile: lexer parser
	$(MAKE) $(OBJS)

compile: lexer_compile parser_compile misc_compile
	$(CXX) $(CXXFLAGS) -o $(OUTPUT) $(OBJS) parser.o lexer.o $(LIBS)

compile_debug: lexer parser
	$(CXX) $(CXXFLAGS) -DDLDEBUG -o $(OUTPUT) \
		main.cpp \
		DragonLispDriver.cpp \
		AST.cpp \
		DragonLisp.tab.cc \
		lex.yy.cc

clean:
	rm -fv \
		lex.backup \
		lex.yy.cc \
		$(PROJ).output \
		$(PROJ).tab.cc \
		$(PROJ).tab.hh \
		stack.hh \
		location.hh \
		parser.o \
		lexer.o \
		$(OBJS) \
		$(OUTPUT)
