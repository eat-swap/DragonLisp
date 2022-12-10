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

float	[+-]?[0-9]*[.][0-9]+([eE][+-][0-9]+)?
int		[+-]?(0[xX][0-9A-Fa-f]*|0[0-7]+|[1-9][0-9]*)
id		[a-zA-Z_][a-zA-Z_0-9]*
blank	[ \t\v\r]
comment	;.*$
string	\"[^\r\n]*\"

%%

%{
	yylval = lval;
%}

{string}	{
	loc->step();
	std::printf("Scanned string: %s\n", yytext);
	yylval->emplace<std::string>(std::string(yytext + 1, yyleng - 2));
	return token::TOKEN_STRING;
}

{comment}	{
	std::printf("Scanned comment: %s\n", yytext);
	loc->step();
}

{blank}+	{
	loc->step();
	std::printf("Skipping blank\n");
	return token::TOKEN_SPACE;
};

\n+		{
	loc->lines(yyleng);
	loc->step();
	std::printf("Skipping newline\n");
	return token::TOKEN_SPACE;
}

{float}	{
	errno = 0;
	char* seq_end_ptr = nullptr;
	double n = strtod(yytext, &seq_end_str);
	if (errno == ERANGE)
		throw DragonLisp::DLParser::syntax_error(*loc, "Float out of range: " + std::string(yytext));
	if (seq_end_ptr - yytext < yyleng)
		throw DragonLisp::DLParser::syntax_error(*loc, "Invalid float scanned: [" + std::string(yytext, seq_end_ptr) + "], but provided [" + std::string(yytext) + "]");
	yylval->emplace<double>(n);
	std::printf("Scanned float: %lf\n", n);
	return TOKEN::TOKEN_FLOAT;
}

{int}	{
	errno = 0;
	char* seq_end_ptr = nullptr;
	int64_t n = strtoll(yytext, &seq_end_ptr, 0);
	if (errno == ERANGE)
		throw DragonLisp::DLParser::syntax_error(*loc, "Integer out of range: " + std::string(yytext));
	if (seq_end_ptr - yytext < yyleng)
		throw DragonLisp::DLParser::syntax_error(*loc, "Invalid integer scanned: [" + std::string(yytext, seq_end_ptr) + "], but provided [" + std::string(yytext) + "]");
	yylval->emplace<int64_t>(n);
	std::printf("Scanned integer: %lld\n", n);
	return token::TOKEN_INTEGER;
};

"<="	{
	std::printf("Scanned <=\n");
	return token::TOKEN_LESS_EQUAL;
};

">="	{
	std::printf("Scanned >=\n");
	return token::TOKEN_GREATER_EQUAL;
};

"<"		{
	std::printf("Scanned <\n");
	return token::TOKEN_LESS;
};

">"		{
	std::printf("Scanned >\n");
	return token::TOKEN_GREATER;
};

"/="	{
	std::printf("Scanned !=\n");
	return token::TOKEN_NOT_EQUAL;
};

"="		{
	std::printf("Scanned =\n");
	return token::TOKEN_EQUAL;
};

"("		{
	std::printf("Scanned (\n");
	return token::TOKEN_LPAREN;
};

")"		{
	std::printf("Scanned )\n");
	return token::TOKEN_RPAREN;
};

"+"		{
	std::printf("Scanned +\n");
	return token::TOKEN_PLUS;
};

"-"		{
	std::printf("Scanned -\n");
	return token::TOKEN_MINUS;
};

"*"		{
	std::printf("Scanned *\n");
	return token::TOKEN_MULTIPLY;
};

"/"		{
	std::printf("Scanned /\n");
	return token::TOKEN_DIVIDE;
};

{id}	{
	std::printf("Scanned identifier: %s\n", yytext);
	yylval->emplace<std::string>(std::string(yytext, yyleng));
	return token::TOKEN_IDENTIFIER;
};

.		{
	throw DragonLisp::DLParser::syntax_error(*loc, "Invalid character: " + std::string(yytext));
};

<<EOF>>	{
	yyterminate();
};

%%
