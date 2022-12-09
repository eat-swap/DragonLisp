%{

#include <cstdio>
#include <cstdint>
#include <iostream>

#include "DragonLispScanner.hh"

#undef YY_DECL
#define YY_DECL int DragonLisp::DLScanner::yylex(DragonLisp::DLParser::semantic_type* const lval, DragonLisp::DLParser::location_type* location, DragonLisp::DLDriver& drv)

using token = DragonLisp::DLParser::token;

#define yyterminate() return token::TOKEN_END;

#define YY_USER_ACTION loc->columns(yyleng);

%}

%option yyclass="DragonLisp::DLScanner"
%option verbose backup warn noyywrap c++ nounistd debug noline

id		[a-zA-Z_][a-zA-Z_0-9]*
int		[0-9]+
blank	[ \t\v\r]

%%

%{
	yylval = lval;
%}

{blank}+	{ loc->step(); }
\n+			{ loc->lines(yyleng); loc->step(); }

"("		{ return token::TOKEN_LPAREN; }
")"		{ return token::TOKEN_RPAREN; }
"+"		{ return token::TOKEN_PLUS; }
"-"		{ return token::TOKEN_MINUS; }
"*"		{ return token::TOKEN_STAR; }
"/"		{ return token::TOKEN_SLASH; }

{int}	{
	errno = 0;
	int64_t n = strtoll(yytext, nullptr, 10);
	if (errno)
		throw DragonLisp::DLParser::syntax_error(*loc, "Invalid integer provided: " + std::string(yytext));
	yylval->emplace<int64_t>(n);
	return token::TOKEN_NUMBER;
};

{id}	{ /* return DragonLisp::DLParser::make_IDENTIFIER(yytext, *loc); */ }

.		{ throw DragonLisp::DLParser::syntax_error(*loc, "Invalid character: " + std::string(yytext)); }

<<EOF>>	{ yyterminate(); }

%%
