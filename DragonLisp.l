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
comment	;[^\n\r]*
string	\"[^\r\n]*\"

and		[aA][nN][dD]
or		[oO][rR]
not		[nN][oO][tT]
max		[mM][aA][xX]
min		[mM][iI][nN]
if		[iI][fF]
logand	[lL][oO][gG][aA][nN][dD]
logior	[lL][oO][gG][iI][oO][rR]
logxor	[lL][oO][gG][xX][oO][rR]
lognor	[lL][oO][gG][nN][oO][rR]
logeqv	[lL][oO][gG][eE][qQ][vV]
mod		[mM][oO][dD]
rem		[rR][eE][mM]
incf	[iI][nN][cC][fF]
decf	[dD][eE][cC][fF]
defvar	[dD][eE][fF][vV][aA][rR]
defun	[dD][eE][fF][uU][nN]
print	[pP][rR][iI][nN][tT]
loop	[lL][oO][oO][pP]
setq	[sS][eE][tT][qQ]
setf	[sS][eE][tT][fF]
quote	[qQ][uU][oO][tT][eE]
for		[fF][oO][rR]
in		[iI][nN]
from	[fF][rR][oO][mM]
to		[tT][oO]
dotimes	[dD][oO][tT][iI][mM][eE][sS]
dolist	[dD][oO][lL][iI][sS][tT]
do		[dD][oO]
aref	[aA][rR][eE][fF]
makearray	[mM][aA][kK][eE][-][aA][rR][rR][aA][yY]
defconstant	[dD][eE][fF][cC][oO][nN][sS][tT][aA][nN][tT]

%%

%{
	yylval = lval;
%}

{blank}+	{
	loc->step();
	std::printf("Skipping blank\n");
	// return token::TOKEN_SPACE;
};

\n+		{
	loc->lines(yyleng);
	loc->step();
	std::printf("Skipping newline\n");
	// return token::TOKEN_SPACE;
}

{float}	{
	errno = 0;
	char* seq_end_ptr = nullptr;
	double n = strtod(yytext, &seq_end_ptr);
	if (errno == ERANGE)
		throw DragonLisp::DLParser::syntax_error(*loc, "Float out of range: " + std::string(yytext));
	if (seq_end_ptr - yytext < yyleng)
		throw DragonLisp::DLParser::syntax_error(*loc, "Invalid float scanned: [" + std::string(yytext, seq_end_ptr) + "], but provided [" + std::string(yytext) + "]");
	yylval->emplace<double>(n);
	std::printf("Scanned float: %lf\n", n);
	return token::TOKEN_FLOAT;
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

{and}	{
	std::printf("Scanned and\n");
	return token::TOKEN_AND;
};

{or}	{
	std::printf("Scanned or\n");
	return token::TOKEN_OR;
};

{not}	{
	std::printf("Scanned not\n");
	return token::TOKEN_NOT;
};

{max}	{
	std::printf("Scanned max\n");
	return token::TOKEN_MAX;
};

{min}	{
	std::printf("Scanned min\n");
	return token::TOKEN_MIN;
};

{if}	{
	std::printf("Scanned if\n");
	return token::TOKEN_IF;
};

{logand}	{
	std::printf("Scanned logand\n");
	return token::TOKEN_LOGAND;
};

{logior}	{
	std::printf("Scanned logior\n");
	return token::TOKEN_LOGIOR;
};

{logxor}	{
	std::printf("Scanned logxor\n");
	return token::TOKEN_LOGXOR;
};

{lognor}	{
	std::printf("Scanned lognor\n");
	return token::TOKEN_LOGNOR;
};

{logeqv}	{
	std::printf("Scanned logeqv\n");
	return token::TOKEN_LOGEQV;
};

{mod}	{
	std::printf("Scanned mod\n");
	return token::TOKEN_MOD;
};

{rem}	{
	std::printf("Scanned rem\n");
	return token::TOKEN_REM;
};

{incf}	{
	std::printf("Scanned incf\n");
	return token::TOKEN_INCF;
};

{decf}	{
	std::printf("Scanned decf\n");
	return token::TOKEN_DECF;
};

{defvar}	{
	std::printf("Scanned defvar\n");
	return token::TOKEN_DEFVAR;
};

{defun}	{
	std::printf("Scanned defun\n");
	return token::TOKEN_DEFUN;
};

{print}	{
	std::printf("Scanned print\n");
	return token::TOKEN_PRINT;
};

{loop}	{
	std::printf("Scanned loop\n");
	return token::TOKEN_LOOP;
};

{setq}	{
	std::printf("Scanned setq\n");
	return token::TOKEN_SETQ;
};

{setf}	{
	std::printf("Scanned setf\n");
	return token::TOKEN_SETF;
};

{quote}	{
	std::printf("Scanned quote\n");
	return token::TOKEN_QUOTE;
};

{for}	{
	std::printf("Scanned for\n");
	return token::TOKEN_FOR;
};

{in}	{
	std::printf("Scanned in\n");
	return token::TOKEN_IN;
};

{from}	{
	std::printf("Scanned from\n");
	return token::TOKEN_FROM;
};

{to}	{
	std::printf("Scanned to\n");
	return token::TOKEN_TO;
};

{dotimes}	{
	std::printf("Scanned dotimes\n");
	return token::TOKEN_DOTIMES;
};

{dolist}	{
	std::printf("Scanned dolist\n");
	return token::TOKEN_DOLIST;
};

{do}	{
	std::printf("Scanned do\n");
	return token::TOKEN_DO;
};

{aref}	{
	std::printf("Scanned aref\n");
	return token::TOKEN_AREF;
};

{makearray}	{
	std::printf("Scanned makearray\n");
	return token::TOKEN_MAKE_ARRAY;
};

{defconstant}	{
	std::printf("Scanned defconstant\n");
	return token::TOKEN_DEFCONSTANT;
};

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
